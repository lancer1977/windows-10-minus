# Install Flow

This is the recommended install flow for Windows 10 Minus.

---

## Before you wipe anything

- [ ] Confirm the target machine and disk.
- [ ] Back up files.
- [ ] Export browser bookmarks if needed.
- [ ] Save BitLocker recovery keys if applicable.
- [ ] Confirm Windows license/source.
- [ ] Download network/chipset/GPU/capture-card drivers from official vendor sources.
- [ ] Create install USB from official media.
- [ ] Have another working machine available in case network drivers are missing.

---

## Path A: Windows 10 Pro 22H2

Use this when Pro is the only license available.

1. Download official Windows 10 media from Microsoft.
2. Create USB with Microsoft Media Creation Tool or Rufus.
3. Boot target machine from USB.
4. Install Windows 10 Pro.
5. Use a local account when possible for appliance-style machines.
6. Install network/chipset/GPU/capture drivers from official vendor sources.
7. Run Windows Update until no more important updates appear.
8. Create restore point or VM snapshot.
9. Run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

10. Reboot.
11. Validate Windows Update, Defender, Store, audio, video, capture card, and target software.
12. Create a disk image.
13. Record the deployment in [docs/templates/machine-inventory.md](templates/machine-inventory.md), including profile, drivers, recovery image, and maintenance dates.

Optional appliance pass after validation:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProAppliance -RemoveOneDrive -RemoveXboxApps
```

---

## Path B: Enterprise evaluation VM

Use this for testing only.

1. Download evaluation media from Microsoft Evaluation Center.
2. Install in Hyper-V, VMware, VirtualBox, or similar.
3. Snapshot before running the script.
4. Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe -WhatIf
.\scripts\Apply-Win10Minus.ps1 -Profile ProSafe
```

5. Validate behavior.
6. Revert snapshot between tests.

---

## Path C: Enterprise LTSC 2021

Use only with legitimate Enterprise LTSC licensing.

1. Install from official/licensed media.
2. Install drivers.
3. Update.
4. Snapshot or restore point.
5. Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile LtscSafe
```

6. Validate.
7. Image the machine.

---

## Path D: IoT Enterprise LTSC 2021

Use only with legitimate IoT Enterprise LTSC licensing.

1. Install from official/OEM/licensed media.
2. Install hardware-specific drivers.
3. Update.
4. Snapshot or restore point.
5. Run:

```powershell
.\scripts\Apply-Win10Minus.ps1 -Profile IotLtscAppliance
```

6. Validate target appliance workload.
7. Image the machine.
8. Record license/source details in machine inventory.

---

## Rufus notes

Use Rufus when you already have an ISO.

Typical modern settings:

- Partition scheme: GPT
- Target system: UEFI
- File system: NTFS or what Rufus chooses

Use MBR/BIOS only for older machines that cannot boot UEFI.

---

## Local account notes

For Windows 10 appliance-style installs, a local account is often simpler.

Tactics:

- Install disconnected from the internet when possible.
- Connect network after first desktop login.
- Avoid signing into a Microsoft account unless the machine needs Store account features, ESU enrollment, OneDrive, Xbox services, or other cloud-linked features.

---

## After cleanup validation

Check:

- [ ] Windows Update opens and scans.
- [ ] Defender/Security app opens.
- [ ] Microsoft Store still opens if expected.
- [ ] Device Manager has no unexpected missing drivers.
- [ ] Audio output/input works.
- [ ] GPU acceleration works.
- [ ] Capture card works if applicable.
- [ ] Browser works.
- [ ] Remote access works if needed.
- [ ] Restore point or disk image exists.
