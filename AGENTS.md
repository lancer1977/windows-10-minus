# Repository Instructions

This repository is documentation-first. Keep changes small, explicit, and easy
to validate from a fresh checkout.

## Validation

- Run `./scripts/validate.sh` before marking work complete.
- If the validation script changes, update `.github/workflows/validate.yml` in the same change.

## Content Rules

- Do not store product keys, passwords, recovery keys, private IP inventories, or other secrets in tracked files.
- Use `docs/templates/` for reusable templates and `docs/examples/` for scrubbed examples only.
- Prefer Markdown checklists for manual Windows cleanup workflows so they can be reviewed and improved over time.
