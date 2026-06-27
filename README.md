# Windows 10 Minus

A conservative Windows 10 cleanup kit for people who want a lighter, quieter Windows 10 install without downloading mystery ISOs.

This repo does **not** provide Windows ISOs, product keys, activation bypasses, or modified Microsoft images.

The goal is:

- Start from official Microsoft media.
- Support multiple legitimate Windows 10 install sources.
- Apply repeatable, inspectable cleanup scripts after install.
- Keep Defender, Windows Update, rollback, and recovery intact.
- Make Windows 10 Pro usable when Pro is the only available license.
- Leave room for LTSC / IoT LTSC profiles when properly licensed.

---

## The practical default

If you only have **Windows 10 Pro**, use this path:

1. Download official Windows 10 installation media from Microsoft.
2. Install Windows 10 Pro 22H2.
3. Run Windows Update.
4. Create a restore point or VM snapshot.
5. Run the `ProSafe` profile.
6. Reboot.
7. Install only the apps/drivers you actually need.

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

Optional for a retro/capture/appliance box:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive -RemoveXboxApps
```

---

## Supported install-source paths

| Path | Who it is for | Support reality | Recommended profile |
|---|---|---|---|
| Windows 10 Pro 22H2 | Most personal machines where Pro is the only available license | Normal support ended October 14, 2025; ESU may be needed | `ProSafe` or `ProAppliance` |
| Windows 10 Enterprise Eval | Temporary testing and VM validation | Evaluation only; not a production license | `ProSafe` for testing script behavior |
| Windows 10 Enterprise LTSC 2021 | Properly licensed org/volume scenarios | Longer-lived than Pro, but not the 2032 IoT lifecycle | `LtscSafe` |
| Windows 10 IoT Enterprise LTSC 2021 | Properly licensed appliance/embedded/OEM scenarios | Extended support through January 13, 2032 | `IotLtscAppliance` |
| Third-party modified ISOs | Disposable/offline experiments only | Unknown security/update state | Not recommended |

See: [docs/iso-options.md](docs/iso-options.md)

---

## Cleanup profiles

| Profile | Intent | Risk level |
|---|---|---|
| `ProSafe` | Quiet down Windows 10 Pro while keeping Store, Defender, Update, and compatibility | Low |
| `ProAppliance` | Stronger cleanup for capture/retro/lab boxes | Medium |
| `LtscSafe` | Minimal tweaks for Enterprise LTSC-style installs | Low |
| `IotLtscAppliance` | Appliance-oriented cleanup for properly licensed IoT LTSC | Medium |

See: [docs/profiles.md](docs/profiles.md)

---

## What this removes or disables

The script can disable or reduce:

- Consumer content suggestions
- Content Delivery Manager nags
- Advertising ID policy
- Bing/Cortana search integration keys
- Suggested apps
- A conservative set of consumer AppX packages
- Optional OneDrive removal
- Optional Xbox app removal

The script intentionally does **not** disable:

- Microsoft Defender
- Windows Update
- Microsoft Store by default
- System Restore by default
- Activation/licensing systems

---

## Repository layout

```text
docs/
  iso-options.md
  profiles.md
  install-flow.md
  test-plan.md
  maintenance.md
  index.md
  templates/machine-inventory.md
scripts/
  Apply-Win10Minus.ps1
  validate.sh
```

---

## Validation

Run the repository validation from a Linux/macOS shell or GitHub Actions:

```bash
./scripts/validate.sh
```

Run the PowerShell cleanup script only in a disposable VM or on a machine that
has a restore point/snapshot:

```powershell
.\scripts\Apply-Win10Minus.ps1 -WhatIf
```

The validation script checks the required docs spine, machine-inventory
template headings, cleanup script parseability when PowerShell is available,
and basic safety wording.

---

## Safety rules

Trust:

- Microsoft download pages
- Microsoft Evaluation Center
- Official OEM/vendor recovery images
- Official Rufus/Winaero/O&O pages
- Transparent scripts you can read before running

Avoid:

- Pre-activated ISOs
- Discord/Telegram ISO links
- “Superlite no Defender no updates” gaming images
- ISO bundles with activators
- Any installer that asks you to disable security first

---

## Status

Initial project scaffold. Treat the script as conservative but still test in a VM before running on a real machine.
