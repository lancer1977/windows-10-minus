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

Run the evidence collector after any scripted run to capture deterministic post-run state (or pass `-EvidencePath` directly to `Apply-Win10Minus.ps1`):

```powershell
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\win10minus-evidence.json
```
(or)

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe -EvidencePath .\artifacts\prosafe-apply.json
```

After collecting evidence, validate JSON shape before filing:

```bash
python3 scripts/validate-win10minus-evidence.py ./artifacts/prosafe-apply.json --pretty
```

To run evidence validation from Linux CI for collected artifacts, set:

```bash
export WIN10MINUS_EVIDENCE_PATHS="/tmp/prosafe-apply.json /tmp/proappliance-apply.json"
./scripts/validate.sh
```

(Create `artifacts/` first as needed.)

### Evidence output contract

Each collected JSON is expected to contain:

- `os`: OS name/version/build and edition.
- `services`: service status and startup state for `WinDefend` and `wuauserv`.
- `appx.store_present`: whether `Microsoft.WindowsStore` is installed.
- `appx.defender_enabled`: real-time protection and cloud block level.
- `scripts.profile_log_exists` plus latest log file path when present.
- `checks`: interactive verification hints for Store, Start menu, browser, Defender, and Update.
- `hardware`: optional device snapshot for audio, capture/video, and display controller basics when available.
- `profile`: selected profile name for that evidence run.

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

Post-check:

```powershell
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\prosafe-whatif.json
```

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

Post-check:

```powershell
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\prosafe-apply.json
```

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

Post-check:

```powershell
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\proappliance-apply.json
```

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

Post-check:

```powershell
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\proappliance-onedrive.json
```

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

Post-check:

```powershell
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\proappliance-xbox.json
```

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
- [ ] Audio endpoints are detected and functioning after reboot.
- [ ] Capture/video devices are detected where expected for retro/capture targets.

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
