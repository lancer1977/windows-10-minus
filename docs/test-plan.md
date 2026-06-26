# VM Test Plan

Use this before running Windows 10 Minus on real hardware.

---

## Test matrix

| Test | Install source | Profile | Required? |
|---|---|---|---|
| Pro safe dry run | Windows 10 Pro 22H2 | `ProSafe -WhatIf` | Yes |
| Pro safe apply | Windows 10 Pro 22H2 | `ProSafe` | Yes |
| Pro appliance dry run | Windows 10 Pro 22H2 | `ProAppliance -WhatIf` | Yes |
| Pro appliance apply | Windows 10 Pro 22H2 | `ProAppliance` | Recommended |
| OneDrive removal | Windows 10 Pro 22H2 | `ProAppliance -RemoveOneDrive` | Optional |
| Xbox removal | Windows 10 Pro 22H2 | `ProAppliance -RemoveXboxApps` | Optional |
| LTSC safe | Enterprise LTSC 2021 | `LtscSafe` | If licensed/media available |
| IoT LTSC appliance | IoT Enterprise LTSC 2021 | `IotLtscAppliance` | If licensed/media available |

---

## Setup

1. Create a VM.
2. Install Windows.
3. Run Windows Update.
4. Install guest tools.
5. Create a clean snapshot named `Before Windows 10 Minus`.
6. Copy repo or script into VM.
7. Open elevated PowerShell.

---

## Test: ProSafe WhatIf

Command:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe -WhatIf
```

Expected:

- No registry writes.
- No AppX removals.
- No OneDrive removal.
- No Explorer restart.
- Summary prints intended registry keys.
- No fatal errors.

---

## Test: ProSafe apply

Command:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

Expected:

- Script completes.
- Log file is created under `%ProgramData%\Windows10Minus\Logs`.
- Restore point is attempted.
- Registry baseline is applied.
- Conservative AppX package removals run.
- Windows Update still works.
- Defender still works.
- Microsoft Store still works.

Rollback:

- Revert VM snapshot.

---

## Test: ProAppliance apply

Command:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance
```

Expected:

- Stronger AppX cleanup than `ProSafe`.
- No Defender/Update removal.
- Store remains available.
- Machine remains usable after reboot.

Rollback:

- Revert VM snapshot.

---

## Test: optional OneDrive removal

Command:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive
```

Expected:

- OneDrive uninstall is attempted if installer exists.
- Script handles missing OneDrive gracefully.
- Startup entry is removed when present.

Rollback:

- Revert VM snapshot.

---

## Test: optional Xbox removal

Command:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveXboxApps
```

Expected:

- Xbox/Gaming package patterns are included.
- Missing packages do not cause fatal errors.
- Game Bar/Xbox features may be removed or reduced.

Rollback:

- Revert VM snapshot.

---

## Validation checklist after each apply run

- [ ] Reboot succeeds.
- [ ] Start menu opens.
- [ ] Settings opens.
- [ ] Windows Update scans.
- [ ] Windows Security opens.
- [ ] Defender status is healthy.
- [ ] Microsoft Store opens unless intentionally removed in a future profile.
- [ ] Browser opens.
- [ ] Event Viewer does not show obvious critical script-caused breakage.
- [ ] Script log exists.

---

## Bug report template

When filing an issue, include:

- Windows edition
- Windows build
- Profile used
- Command line used
- Whether VM or physical hardware
- Script commit hash
- Relevant log excerpt
- What broke
- Whether rollback worked
