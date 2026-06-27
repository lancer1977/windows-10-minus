# Windows 10 Minus Docs

This documentation area tracks reusable cleanup and inventory material for
Windows machine reduction or decommissioning work.

## Templates

- [Machine inventory](templates/machine-inventory.md)

## Cleanup Workflow

- [ISO options](iso-options.md)
- [Cleanup profiles](profiles.md)
- [Install flow](install-flow.md)
- [VM test plan](test-plan.md)
- [Maintenance checklist](maintenance.md)

## Validation

Run `./scripts/validate.sh` from the repository root. The validation checks for
required top-level docs, cleanup workflow docs, script presence, and required
headings in the machine inventory template. When PowerShell is installed, it
also parses `scripts/Apply-Win10Minus.ps1`.

## Backlog Seeds

- Add a sanitized example inventory.
- Add a pre-disposition checklist.
- Add a post-disposition verification checklist.
- Add a software/license removal checklist.
- Add a backup and recovery confirmation checklist.
