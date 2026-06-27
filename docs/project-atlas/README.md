# Project Atlas

## Purpose

`windows-10-minus` holds reusable documentation and validation for Windows
machine cleanup, inventory, and disposition workflows.

## Repo Shape

- Documentation-first repository.
- Templates live under `docs/templates/`.
- Validation is handled by `./scripts/validate.sh`.
- GitHub Actions runs the same validation command.

## Ownership Boundaries

- Public repo content should stay generic and scrubbed.
- Private machine inventories, credentials, recovery keys, and license details
  must stay outside this repository.

## Current Tracker

- Repo issue: https://github.com/lancer1977/windows-10-minus/issues/5
- Parent epic: https://github.com/lancer1977/dev-forge/issues/440
