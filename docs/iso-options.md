# ISO and Install Source Options

Windows 10 Minus is built around a simple rule:

> Use official Microsoft or OEM media, then make Windows lighter with scripts you can inspect.

This repo does not host ISOs, modified Windows images, activators, keys, or bypass tools.

---

## Current best path if you only have Windows 10 Pro

Use **Windows 10 Pro 22H2** from the official Microsoft download flow, then apply the `ProSafe` profile.

This is the most practical path when:

- You already have a Windows 10 Pro license.
- The machine is a retro/capture/lab box.
- You want fewer nags without gambling on third-party ISOs.
- You want normal compatibility with common drivers and software.

Important support reality:

- Normal Windows 10 Home/Pro support ended on October 14, 2025.
- Windows 10 22H2 is the final normal Windows 10 feature version.
- Consider ESU, isolation, or migration planning for internet-connected machines.

Official links:

- Windows 10 download / Media Creation Tool: https://www.microsoft.com/software-download/windows10
- Create Windows installation media: https://support.microsoft.com/en-us/windows/create-installation-media-for-windows-99a58364-8c02-206f-aa6f-40c3b507420d
- Windows 10 Home and Pro lifecycle: https://learn.microsoft.com/en-us/lifecycle/products/windows-10-home-and-pro
- Windows release information: https://learn.microsoft.com/en-us/windows/release-health/release-information
- Windows 10 Extended Security Updates: https://learn.microsoft.com/en-us/windows/whats-new/extended-security-updates

Recommended profile:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

Optional stronger cleanup:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive -RemoveXboxApps
```

---

## Windows 10 Enterprise evaluation path

Use this only for testing.

Good for:

- Validating script behavior in a VM.
- Testing driver/application compatibility.
- Building screenshots/docs.

Not good for:

- Long-term production use.
- License workaround.
- Appliance builds you want to keep forever.

Official links:

- Microsoft Evaluation Center: https://www.microsoft.com/en-us/evalcenter
- Windows 10 Enterprise evaluation page, when available: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise

Recommended profile for testing:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

---

## Windows 10 Enterprise LTSC 2021 path

This is for properly licensed Enterprise LTSC scenarios.

Good for:

- Organizations with legitimate volume licensing.
- Stable machines that do not need consumer Windows features.
- Test/lab validation where the license path is legitimate.

Important distinction:

- Windows 10 Enterprise LTSC 2021 and Windows 10 IoT Enterprise LTSC 2021 have different lifecycle/licensing expectations.
- Do not assume Enterprise LTSC gives the same long runway as IoT Enterprise LTSC.

Recommended profile:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile LtscSafe
```

---

## Windows 10 IoT Enterprise LTSC 2021 path

This is the ideal Windows 10 long-term appliance path **when properly licensed**.

Good for:

- Purpose-built appliance machines.
- Capture/retro boxes.
- Kiosk-like workstations.
- Embedded/OEM-style devices.
- Machines that need stability more than Microsoft consumer features.

Support reality:

- Microsoft lists Windows 10 IoT Enterprise LTSC 2021 extended support through January 13, 2032.
- This is the long-term Windows 10 target if licensing is legitimate.

Official links:

- Windows 10 IoT Enterprise LTSC 2021 lifecycle: https://learn.microsoft.com/en-us/lifecycle/products/windows-10-iot-enterprise-ltsc-2021
- Windows IoT Enterprise docs: https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/

Recommended profile:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile IotLtscAppliance
```

---

## Third-party modified ISO path

Examples include Tiny10-style or gaming/superlite builds.

This repo does not recommend them for real machines.

Problems:

- Unknown changes.
- Unknown security posture.
- Unknown update reliability.
- Unknown credential safety.
- Often stripped too aggressively.
- Sometimes bundled with activation bypasses.

Maybe acceptable only for:

- Disposable VM.
- Offline experiment.
- No credentials.
- No banking, GitHub, Microsoft, Google, work SSO, or personal accounts.

Recommended repo stance:

- Document risks.
- Do not link mirrors.
- Do not automate activation bypasses.
- Do not support modified images as the primary path.

---

## USB creation tools

### Rufus

Official site:

https://rufus.ie/

GitHub:

https://github.com/pbatard/rufus

Use Rufus when you already have an ISO and want to make a USB installer.

### Microsoft Media Creation Tool

Official page:

https://www.microsoft.com/software-download/windows10

Use this when you want Microsoft to create the ISO or USB directly.

---

## Recommended decision tree

1. Do you have a legitimate Windows 10 IoT Enterprise LTSC 2021 license?
   - Yes: use IoT LTSC + `IotLtscAppliance`.
   - No: continue.

2. Do you have legitimate Enterprise LTSC licensing?
   - Yes: use LTSC + `LtscSafe`.
   - No: continue.

3. Do you only have Windows 10 Pro?
   - Yes: use official Windows 10 Pro 22H2 + `ProSafe`.
   - For appliance/retro/capture box, consider `ProAppliance` after testing.

4. Is this just a VM test?
   - Use Enterprise evaluation or Pro media and snapshot first.

5. Are you considering a modified third-party ISO?
   - Only do this offline/disposable.
   - Do not put real credentials on it.

---

## Last reviewed

Initial review: 2026-06-26
