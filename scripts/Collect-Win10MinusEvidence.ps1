[CmdletBinding()]
param(
    [string]$Profile = '',
    [string]$ProfileLogPath = "${env:ProgramData}\Windows10Minus\Logs",
    [string]$EvidencePath = "${env:TEMP}\win10minus-evidence.json"
)

$artifactDir = Split-Path -Path $EvidencePath -Parent
if ([string]::IsNullOrWhiteSpace($artifactDir)) {
    $artifactDir = (Get-Location).Path
}
if (-not (Test-Path -Path $artifactDir)) {
    $null = New-Item -Path $artifactDir -ItemType Directory -Force
}

$errors = @()

function Invoke-SafeTest {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
    } catch {
        $errors += [pscustomobject]@{
            name = $Name
            message = $_.ToString()
        }
        Write-Warning "[$Name] $($_.Exception.Message)"
        $null
    }
}

$evidence = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    hostname = $env:COMPUTERNAME
    profile = if ([string]::IsNullOrWhiteSpace($Profile)) { $null } else { $Profile }
    powershell = [ordered]@{
        version = if ($PSVersionTable.PSVersion) { $PSVersionTable.PSVersion.ToString() } else { $null }
        edition = if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { $null }
    }
    os = [ordered]@{}
    services = [ordered]@{}
    appx = [ordered]@{}
    hardware = [ordered]@{}
    scripts = [ordered]@{}
    checks = [ordered]@{}
    errors = @()
}

$computerInfo = Invoke-SafeTest -Name "Get-ComputerInfo" -ScriptBlock { Get-ComputerInfo -Property OSName,OsVersion,OsBuildNumber,WindowsVersion,WindowsBuildLabEx,SystemFamily }
if ($computerInfo) {
    $evidence.os = [ordered]@{
        os_name = $computerInfo.OSName
        os_version = $computerInfo.OsVersion
        os_build = $computerInfo.OsBuildNumber
        windows_version = $computerInfo.WindowsVersion
        build_lab_ex = $computerInfo.WindowsBuildLabEx
        system_family = $computerInfo.SystemFamily
        is_64bit = [Environment]::Is64BitOperatingSystem
    }
}

$serviceNames = @('WinDefend','wuauserv','sppsvc','bits','TrkWks','UsoSvc','sihsvc')
foreach ($svc in $serviceNames) {
    $s = Invoke-SafeTest -Name "Service:$svc" -ScriptBlock { Get-Service -Name $svc -ErrorAction Stop }
    if ($s) {
        $evidence.services[$svc] = [ordered]@{
            status = $s.Status
            start_type = $s.StartType
        }
    }
}

$store = Invoke-SafeTest -Name "StoreAppx" -ScriptBlock {
    Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction SilentlyContinue
}
$evidence.appx.store_present = [bool]($null -ne $store)

$eventLog = Invoke-SafeTest -Name "DefenderPrefs" -ScriptBlock {
    Get-MpPreference
}
if ($eventLog) {
    $evidence.appx.defender_enabled = [ordered]@{
        real_time_protection = $eventLog.RealTimeProtectionEnabled
        cloud_block_level = $eventLog.CloudBlockLevel
        sandbox_mode = $eventLog.Sandbox
    }
    $evidence.appx.defender_exclusion_paths = if ($eventLog.ExclusionPath) {
        $eventLog.ExclusionPath | Select-Object -First 5
    } else {
        @()
    }
}

$evidence.scripts.profile_log_path = $ProfileLogPath
$evidence.scripts.profile_log_exists = Test-Path -Path $ProfileLogPath
$evidence.scripts.artifact_path = (Resolve-Path -Path $artifactDir).Path
$evidence.scripts.profile_log_file_count = if ($evidence.scripts.profile_log_exists) {
    (Get-ChildItem -Path $ProfileLogPath -File -ErrorAction SilentlyContinue |
        Measure-Object).Count
} else {
    0
}
if ($evidence.scripts.profile_log_exists) {
    $evidence.scripts.profile_log_latest = Get-ChildItem -Path $ProfileLogPath -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 |
        ForEach-Object { $_.FullName }
}

$audioDevices = Invoke-SafeTest -Name "AudioDevices" -ScriptBlock {
    Get-CimInstance -ClassName Win32_SoundDevice -ErrorAction Stop | ForEach-Object {
        [pscustomobject]@{
            name = $_.Name
            manufacturer = $_.Manufacturer
            status = $_.Status
            enabled = $_.Status -eq 'OK'
            device_id = $_.DeviceID
        }
    }
}
$captureDevices = Invoke-SafeTest -Name "CaptureDevices" -ScriptBlock {
    Get-PnpDevice -Class Media | Where-Object { $_.FriendlyName -match 'camera|capture|webcam|video|audio|microphone|snd|headset|display' } |
        Select-Object -First 20 |
        ForEach-Object {
            [pscustomobject]@{
                name = $_.FriendlyName
                status = $_.Status
                class = $_.Class
            }
        }
}
$displayDevices = Invoke-SafeTest -Name "DisplayControllers" -ScriptBlock {
    Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop | ForEach-Object {
        [pscustomobject]@{
            name = $_.Name
            adapter_ram_mb = if ($_.AdapterRam -and $_.AdapterRam -is [long]) { [math]::Round($_.AdapterRam / 1MB, 2) } else { $null }
            driver = $_.DriverVersion
            status = $_.Status
        }
    }
}
$evidence.hardware = [ordered]@{
    audio_devices = if ($audioDevices) { @($audioDevices) } else { @() }
    capture_devices = if ($captureDevices) { @($captureDevices) } else { @() }
    display_controllers = if ($displayDevices) { @($displayDevices) } else { @() }
}

$evidence.scripts.critical_updates = Invoke-SafeTest -Name "WindowsUpdateCatalog" -ScriptBlock {
    (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0').Updates.Count
}
$updateCatalogCheckError = $errors | Where-Object name -eq "WindowsUpdateCatalog"
$evidence.scripts.update_catalog_error = [bool]($updateCatalogCheckError.Count -gt 0)
$evidence.scripts.is_admin = [bool](New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$evidence.checks.store_open_hint = 'Verify interactively: Start > Microsoft Store launches.'
$evidence.checks.start_menu_hint = 'Verify interactively: Start menu opens and Search works.'
$evidence.checks.browser_hint = 'Verify interactively: Browser launches.'
$evidence.checks.defender_hint = 'Verify interactively: Windows Security opens and scan UI appears.'
$evidence.checks.update_hint = 'Verify interactively: Windows Update can check for updates.'
$evidence.checks.windows_update_hint = 'Verify interactively: Windows Update reports up to date status or lists available updates.'

$evidence.errors = $errors

$evidence | ConvertTo-Json -Depth 6 | Set-Content -Path $EvidencePath -Encoding UTF8
Write-Host "Evidence written to: $EvidencePath"
return $evidence
