<#
.SYNOPSIS
    Windows 10 Minus conservative cleanup profiles.

.DESCRIPTION
    Applies inspectable post-install cleanup profiles for legitimate Windows 10 installs.

    This script does not provide ISOs, activation bypasses, keys, or license workarounds.

    Safe defaults:
    - Keeps Microsoft Defender enabled
    - Keeps Windows Update enabled
    - Keeps Microsoft Store by default
    - Attempts a restore point unless skipped
    - Supports -WhatIf
    - Does not run remote scripts

.EXAMPLE
    .\Apply-Win10Minus.ps1 -Profile ProSafe

.EXAMPLE
    .\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive -RemoveXboxApps

.EXAMPLE
    .\Apply-Win10Minus.ps1 -Profile ProSafe -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('ProSafe', 'ProAppliance', 'LtscSafe', 'IotLtscAppliance')]
    [string]$Profile = 'ProSafe',

    [switch]$RemoveOneDrive,
    [switch]$RemoveXboxApps,
    [switch]$SkipRestorePoint,
    [switch]$SkipAppxRemoval,
    [switch]$SkipExplorerRestart,

    [string]$LogPath = "$env:ProgramData\Windows10Minus\Logs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RegistryChanges = New-Object System.Collections.Generic.List[object]
$script:PackagesRemoved = New-Object System.Collections.Generic.List[object]
$script:Warnings = New-Object System.Collections.Generic.List[string]

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Add-WtmWarning {
    param([Parameter(Mandatory)] [string]$Message)
    $script:Warnings.Add($Message) | Out-Null
    Write-Warning $Message
}

function Start-WtmTranscript {
    if ($WhatIfPreference) {
        Write-Host 'WhatIf mode: transcript logging is skipped to avoid unnecessary filesystem writes.' -ForegroundColor Yellow
        return
    }

    try {
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }

        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $logFile = Join-Path $LogPath "Apply-Win10Minus-$Profile-$stamp.log"
        Start-Transcript -Path $logFile -Force | Out-Null
        Write-Host "Logging to $logFile" -ForegroundColor DarkGray
    }
    catch {
        Add-WtmWarning "Could not start transcript logging: $($_.Exception.Message)"
    }
}

function Stop-WtmTranscript {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
        # Ignore when transcript was not started.
    }
}

function Get-WtmOsSummary {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    [pscustomobject]@{
        Caption = $os.Caption
        Version = $os.Version
        BuildNumber = $os.BuildNumber
        ProductType = $os.ProductType
        InstallDate = $os.InstallDate
    }
}

function Ensure-RegistryKey {
    param([Parameter(Mandatory)] [string]$Path)

    if (-not (Test-Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, 'Create registry key')) {
            New-Item -Path $Path -Force | Out-Null
        }
    }
}

function Set-RegistryDword {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [int]$Value
    )

    Ensure-RegistryKey -Path $Path

    $previous = $null
    try {
        $existing = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($existing) {
            $previous = $existing.$Name
        }
    }
    catch {
        $previous = $null
    }

    if ($PSCmdlet.ShouldProcess("$Path\\$Name", "Set DWORD to $Value")) {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
    }

    $script:RegistryChanges.Add([pscustomobject]@{
        Path = $Path
        Name = $Name
        Previous = $previous
        Desired = $Value
    }) | Out-Null
}

function Invoke-QuietPolicyBaseline {
    Write-Host 'Applying quiet policy baseline...' -ForegroundColor Cyan

    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Value 1
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -Value 1
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Value 1
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'DisabledByGroupPolicy' -Value 1

    # 1 = Security/basic telemetry where supported. Do not set unsupported Enterprise-only values for Pro.
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 1

    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Value 0
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0
}

function Invoke-CurrentUserQuietBaseline {
    Write-Host 'Applying current-user quiet baseline...' -ForegroundColor Cyan

    $contentDelivery = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $cdmValues = @(
        'ContentDeliveryAllowed',
        'FeatureManagementEnabled',
        'OemPreInstalledAppsEnabled',
        'PreInstalledAppsEnabled',
        'PreInstalledAppsEverEnabled',
        'SilentInstalledAppsEnabled',
        'SoftLandingEnabled',
        'SubscribedContent-310093Enabled',
        'SubscribedContent-314559Enabled',
        'SubscribedContent-338387Enabled',
        'SubscribedContent-338388Enabled',
        'SubscribedContent-338389Enabled',
        'SubscribedContent-338393Enabled',
        'SubscribedContent-353694Enabled',
        'SubscribedContent-353696Enabled',
        'SystemPaneSuggestionsEnabled'
    )

    foreach ($name in $cdmValues) {
        Set-RegistryDword -Path $contentDelivery -Name $name -Value 0
    }

    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0
}

function Get-AppxPatternsForProfile {
    $patterns = New-Object System.Collections.Generic.List[string]

    switch ($Profile) {
        'ProSafe' {
            $patterns.AddRange([string[]]@(
                'Microsoft.BingNews',
                'Microsoft.BingWeather',
                'Microsoft.GetHelp',
                'Microsoft.Getstarted',
                'Microsoft.Microsoft3DViewer',
                'Microsoft.MicrosoftOfficeHub',
                'Microsoft.MicrosoftSolitaireCollection',
                'Microsoft.MixedReality.Portal',
                'Microsoft.People',
                'Microsoft.SkypeApp',
                'Microsoft.Wallet',
                'Microsoft.WindowsFeedbackHub',
                'Microsoft.YourPhone',
                'Microsoft.ZuneMusic',
                'Microsoft.ZuneVideo'
            ))
        }
        'ProAppliance' {
            $patterns.AddRange([string[]]@(
                'Microsoft.BingNews',
                'Microsoft.BingWeather',
                'Microsoft.GetHelp',
                'Microsoft.Getstarted',
                'Microsoft.Microsoft3DViewer',
                'Microsoft.MicrosoftOfficeHub',
                'Microsoft.MicrosoftSolitaireCollection',
                'Microsoft.MixedReality.Portal',
                'Microsoft.People',
                'Microsoft.SkypeApp',
                'Microsoft.Wallet',
                'Microsoft.WindowsAlarms',
                'Microsoft.WindowsFeedbackHub',
                'Microsoft.YourPhone',
                'Microsoft.ZuneMusic',
                'Microsoft.ZuneVideo'
            ))
        }
        'LtscSafe' {
            # LTSC images are already lighter. Keep removals minimal.
            $patterns.AddRange([string[]]@(
                'Microsoft.GetHelp',
                'Microsoft.WindowsFeedbackHub'
            ))
        }
        'IotLtscAppliance' {
            # IoT LTSC may not have many consumer packages, but these patterns are safe if present.
            $patterns.AddRange([string[]]@(
                'Microsoft.GetHelp',
                'Microsoft.Getstarted',
                'Microsoft.WindowsFeedbackHub'
            ))
        }
    }

    if ($RemoveXboxApps) {
        $patterns.AddRange([string[]]@(
            'Microsoft.GamingApp',
            'Microsoft.Xbox*'
        ))
    }

    return $patterns.ToArray() | Select-Object -Unique
}

function Remove-AppxPackageByNamePattern {
    param([Parameter(Mandatory)] [string[]]$Patterns)

    foreach ($pattern in $Patterns) {
        Write-Host "Checking AppX pattern: $pattern" -ForegroundColor DarkGray

        $installed = Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue
        foreach ($pkg in $installed) {
            if ($PSCmdlet.ShouldProcess($pkg.PackageFullName, 'Remove installed AppX package')) {
                try {
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                    $script:PackagesRemoved.Add([pscustomobject]@{
                        Type = 'Installed'
                        Name = $pkg.Name
                        Package = $pkg.PackageFullName
                    }) | Out-Null
                }
                catch {
                    Add-WtmWarning "Could not remove installed package $($pkg.Name): $($_.Exception.Message)"
                }
            }
        }

        $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern }
        foreach ($pkg in $provisioned) {
            if ($PSCmdlet.ShouldProcess($pkg.DisplayName, 'Remove provisioned AppX package')) {
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
                    $script:PackagesRemoved.Add([pscustomobject]@{
                        Type = 'Provisioned'
                        Name = $pkg.DisplayName
                        Package = $pkg.PackageName
                    }) | Out-Null
                }
                catch {
                    Add-WtmWarning "Could not remove provisioned package $($pkg.DisplayName): $($_.Exception.Message)"
                }
            }
        }
    }
}

function Remove-OneDriveIfRequested {
    if (-not $RemoveOneDrive) {
        return
    }

    Write-Host 'Attempting OneDrive removal...' -ForegroundColor Yellow

    $oneDriveSetup = Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe'
    if (-not (Test-Path $oneDriveSetup)) {
        $oneDriveSetup = Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'
    }

    if (Test-Path $oneDriveSetup) {
        if ($PSCmdlet.ShouldProcess($oneDriveSetup, 'Run OneDrive uninstall')) {
            Start-Process -FilePath $oneDriveSetup -ArgumentList '/uninstall' -Wait
        }
    }
    else {
        Add-WtmWarning 'OneDriveSetup.exe was not found.'
    }

    $oneDriveRunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path $oneDriveRunKey) {
        if ($PSCmdlet.ShouldProcess($oneDriveRunKey, 'Remove OneDrive startup entry')) {
            Remove-ItemProperty -Path $oneDriveRunKey -Name 'OneDrive' -ErrorAction SilentlyContinue
        }
    }
}

function New-RestorePointIfNeeded {
    if ($SkipRestorePoint) {
        Write-Host 'Restore point skipped by parameter.' -ForegroundColor Yellow
        return
    }

    if ($WhatIfPreference) {
        Write-Host 'WhatIf mode: restore point creation skipped.' -ForegroundColor Yellow
        return
    }

    try {
        if ($PSCmdlet.ShouldProcess('System Restore', 'Create restore point')) {
            Checkpoint-Computer -Description "Before Windows 10 Minus - $Profile" -RestorePointType 'MODIFY_SETTINGS'
            Write-Host 'Created restore point.' -ForegroundColor Green
        }
    }
    catch {
        Add-WtmWarning "Restore point could not be created: $($_.Exception.Message)"
    }
}

function Restart-ExplorerIfNeeded {
    if ($SkipExplorerRestart) {
        Write-Host 'Explorer restart skipped by parameter.' -ForegroundColor Yellow
        return
    }

    if ($WhatIfPreference) {
        Write-Host 'WhatIf mode: Explorer restart skipped.' -ForegroundColor Yellow
        return
    }

    if ($PSCmdlet.ShouldProcess('explorer.exe', 'Restart Explorer')) {
        Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
    }
}

function Write-Summary {
    Write-Host ''
    Write-Host 'Windows 10 Minus summary' -ForegroundColor Cyan
    Write-Host '========================' -ForegroundColor Cyan
    Write-Host "Profile: $Profile"

    Write-Host ''
    Write-Host 'Registry changes requested:' -ForegroundColor Cyan
    if ($script:RegistryChanges.Count -gt 0) {
        $script:RegistryChanges | Format-Table -AutoSize | Out-String | Write-Host
    }
    else {
        Write-Host 'None'
    }

    Write-Host ''
    Write-Host 'Packages removed/requested:' -ForegroundColor Cyan
    if ($script:PackagesRemoved.Count -gt 0) {
        $script:PackagesRemoved | Format-Table -AutoSize | Out-String | Write-Host
    }
    else {
        Write-Host 'None recorded. This can be normal if packages were not present or -WhatIf was used.'
    }

    if ($script:Warnings.Count -gt 0) {
        Write-Host ''
        Write-Host 'Warnings:' -ForegroundColor Yellow
        foreach ($warning in $script:Warnings) {
            Write-Host "- $warning" -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Write-Host 'Reboot recommended.' -ForegroundColor Green
}

try {
    if (-not (Test-IsAdministrator)) {
        throw 'Run this script from an elevated PowerShell prompt.'
    }

    Start-WtmTranscript

    Write-Host "Applying Windows 10 Minus profile: $Profile" -ForegroundColor Cyan

    $os = Get-WtmOsSummary
    Write-Host "Detected OS: $($os.Caption) $($os.Version) build $($os.BuildNumber)" -ForegroundColor DarkGray

    if ($os.Caption -notlike '*Windows 10*') {
        Add-WtmWarning "This script is intended for Windows 10. Detected: $($os.Caption)"
    }

    New-RestorePointIfNeeded
    Invoke-QuietPolicyBaseline
    Invoke-CurrentUserQuietBaseline

    if ($SkipAppxRemoval) {
        Write-Host 'AppX removal skipped by parameter.' -ForegroundColor Yellow
    }
    else {
        $patterns = Get-AppxPatternsForProfile
        Remove-AppxPackageByNamePattern -Patterns $patterns
    }

    Remove-OneDriveIfRequested
    Restart-ExplorerIfNeeded
    Write-Summary
}
finally {
    Stop-WtmTranscript
}
