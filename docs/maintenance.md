# Maintenance Checklist

Windows 10 Minus should stay boring, safe, and current.

---

## Monthly checks

- [ ] Run Windows Update on maintained machines.
- [ ] Confirm Defender/security status.
- [ ] Confirm important apps still work.
- [ ] Confirm capture/audio/video devices still work.
- [ ] Update recovery image after major changes.

---

## Quarterly repo checks

- [ ] Re-check Microsoft Windows 10 download link.
- [ ] Re-check Microsoft lifecycle pages.
- [ ] Re-check Windows 10 ESU guidance.
- [ ] Re-check IoT Enterprise LTSC 2021 lifecycle page.
- [ ] Re-check Rufus link.
- [ ] Re-check O&O ShutUp10++ link if referenced.
- [ ] Re-check Winaero Tweaker link if referenced.
- [ ] Run the test plan against a fresh VM.
- [ ] Review open issues for script safety problems.

---

## Machine inventory

For each machine using this project, track:

- Machine name
- Purpose
- Windows edition
- Install source
- License/source notes
- Script profile used
- Script commit used
- Driver sources
- Recovery image location
- Last update check
- Next maintenance date

---

## Support posture

Windows 10 Pro:

- Treat as legacy after October 14, 2025.
- Use ESU if eligible/needed.
- Avoid high-risk browsing and credential-heavy workloads if not receiving updates.
- Consider network isolation for appliance-style boxes.

Windows 10 IoT Enterprise LTSC 2021:

- Track the January 13, 2032 extended support end date.
- Keep license/source details with inventory.
- Keep Windows Update enabled unless the machine is intentionally offline and separately managed.

---

## Repo principles

- Do not add activators.
- Do not add product keys.
- Do not link ISO mirrors.
- Do not recommend modified ISOs for real credentialed machines.
- Do not disable Defender/Update as a default profile behavior.
- Prefer opt-in switches for risky changes.
