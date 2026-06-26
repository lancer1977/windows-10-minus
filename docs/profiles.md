# Cleanup Profiles

Windows 10 Minus uses profiles so the same repo can support multiple legitimate install sources without pretending they are equivalent.

Profiles are post-install cleanup modes. They are not ISOs.

---

## Profile summary

| Profile | Target install | Intent | Default risk |
|---|---|---|---|
| `ProSafe` | Windows 10 Pro 22H2 | Quiet down Pro while keeping broad compatibility | Low |
| `ProAppliance` | Windows 10 Pro 22H2 | Stronger cleanup for retro/capture/lab boxes | Medium |
| `LtscSafe` | Windows 10 Enterprise LTSC 2021 | Minimal cleanup because LTSC is already lighter | Low |
| `IotLtscAppliance` | Windows 10 IoT Enterprise LTSC 2021 | Appliance-oriented cleanup for long-lived boxes | Medium |

---

## ProSafe

Use this first when Windows 10 Pro is the only available license.

Designed for:

- General Windows 10 Pro install
- Dev box fallback
- Retro box with normal software needs
- Capture card PC
- Lab machine

Actions:

- Disable Windows consumer feature policy.
- Disable soft landing/suggestion policies.
- Disable Windows Spotlight feature policy.
- Disable advertising ID policy.
- Reduce Content Delivery Manager suggestions.
- Disable Bing/Cortana search integration keys.
- Disable activity history upload/publish policy.
- Remove conservative consumer AppX packages.
- Preserve Microsoft Store.
- Preserve Defender.
- Preserve Windows Update.

Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

---

## ProAppliance

Use this for a Windows 10 Pro machine that acts more like an appliance.

Designed for:

- Capture machine
- Retro/emulation machine
- Offline or semi-offline tool box
- Kiosk-ish workstation
- Lab box

Additional assumptions:

- You want fewer bundled apps.
- You can tolerate more aggressive cleanup.
- You have a restore point, VM snapshot, or disk image.

Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance
```

Common optional flags:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive -RemoveXboxApps
```

Do not use `ProAppliance` first on a daily-driver machine without testing.

---

## LtscSafe

Use this for properly licensed Windows 10 Enterprise LTSC 2021.

Designed for:

- Stable enterprise/lab installs
- Machines where consumer features are already mostly absent
- Minimal changes after install

Actions:

- Apply policy and shell quieting.
- Skip broad AppX removal by default.
- Keep compatibility/security pieces intact.

Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile LtscSafe
```

---

## IotLtscAppliance

Use this for properly licensed Windows 10 IoT Enterprise LTSC 2021.

Designed for:

- Purpose-built appliance machines
- Embedded/OEM-style boxes
- Long-lived capture/retro machines
- Machines that should stay stable and quiet for years

Actions:

- Apply quieting policy.
- Apply appliance-oriented tweaks.
- Remove only optional packages that exist.
- Keep Defender and Windows Update intact.

Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile IotLtscAppliance
```

---

## Optional switches

| Switch | Meaning |
|---|---|
| `-WhatIf` | Show intended changes without applying them |
| `-RemoveOneDrive` | Attempt OneDrive uninstall and startup cleanup |
| `-RemoveXboxApps` | Include Xbox/Gaming App package patterns in AppX cleanup |
| `-SkipRestorePoint` | Do not try to create a restore point |
| `-SkipAppxRemoval` | Only apply registry/policy tweaks |
| `-SkipExplorerRestart` | Do not restart Explorer at the end |
| `-LogPath` | Save transcript logs to a custom directory |

---

## Safety posture

Always preserve by default:

- Microsoft Defender
- Windows Update
- Microsoft Store
- System Restore attempt
- Activation/licensing services

Optional removal should require explicit switches.

---

## Recommended rollout

1. Test `-WhatIf`.
2. Run in a VM or snapshot first.
3. Run `ProSafe` first on Windows 10 Pro.
4. Reboot and validate.
5. Only then consider `ProAppliance` or optional removal flags.
