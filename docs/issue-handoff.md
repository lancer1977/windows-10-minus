# Windows 10 Minus Issue Handoff - 2026-06-28

This file maps the open Windows issues to local implementation state, validation, and remaining manual gates.

## Local validation

- `./scripts/validate.sh` (currently: passes; `pwsh` parser validation is skipped without PowerShell installed)
- `docs/` spine and templates updated for evidence-first testing flow.
- `scripts/Collect-Win10MinusEvidence.ps1` added to capture deterministic post-run checks.

## Issue mapping

### #1 Epic: Make Windows 10 Minus the final lightweight Windows 10 kit

Current status: implemented document/scaffolding work is present; manual VM execution still pending.

Implemented locally:

- Evidence-first workflow in `docs/install-flow.md` and `docs/test-plan.md`.
- Machine tracking template now includes driver/license/profile/recovery fields.
- Script now supports optional evidence emission with `-EvidencePath` (`scripts/Apply-Win10Minus.ps1`).
- Script parser/required files are enforced by `scripts/validate.sh`.
- `README.md` links machine-inventory template for deployment records.

Blocking for complete close-out:

- A clean Windows 10 Pro 22H2 VM pass for `-WhatIf` and `ProSafe` is still required.
- Evidence JSON from the actual run is still pending (`-EvidencePath`).

### #2 Test ProSafe profile on a clean Windows 10 Pro VM

Current status: local flow ready; execution blocker is a clean VM environment.

Local-ready evidence:

- `docs/test-plan.md` now includes exact post-check commands:
- `.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\prosafe-apply.json`
- `scripts/validate-win10minus-evidence.py` added for evidence JSON schema checks.
- `docs/templates/machine-inventory.md` added fields for profile/driver/recovery tracking.
- `Apply-Win10Minus.ps1` supports `-WhatIf` and `-EvidencePath`.

Next step:

- Run the documented test plan in a clean Win 10 Pro VM and upload evidence JSON.

### #3 Add ProAppliance validation for retro and capture boxes

Current status: local preconditions and test plan expanded; physical capture validation still pending.

Local-ready evidence:

- `docs/test-plan.md` captures ProAppliance smoke paths and required checks for capture/audio devices.
- `Collect-Win10MinusEvidence.ps1` includes hardware summary (audio/capture/display) and service checks.
- `Apply-Win10Minus.ps1` supports `ProAppliance` flows and optional `-EvidencePath`.
- Evidence schema validation now supports ProAppliance outputs via
  `python3 scripts/validate-win10minus-evidence.py <artifact>.json --pretty`.

Next step:

- Run the `ProAppliance`, `-RemoveOneDrive`, and `-RemoveXboxApps` plans in a clean lab VM and capture evidence JSON.

## Current execution command set

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe -WhatIf
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe -EvidencePath .\artifacts\prosafe-whatif.json
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe -EvidencePath .\artifacts\prosafe-apply.json
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive -EvidencePath .\artifacts\proappliance-onedrive.json
.\scripts\Collect-Win10MinusEvidence.ps1 -EvidencePath .\artifacts\proappliance-apply.json -Profile ProAppliance
```
