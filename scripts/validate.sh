#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "README.md"
  "repo-state.md"
  "code_health.md"
  "docs/index.md"
  "docs/install-flow.md"
  "docs/iso-options.md"
  "docs/maintenance.md"
  "docs/profiles.md"
  "docs/test-plan.md"
  "docs/templates/machine-inventory.md"
  "scripts/Apply-Win10Minus.ps1"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

required_headings=(
  "## Machine Details"
  "## System"
  "## Hardware"
  "## Network"
  "## Notes"
  "## Last Updated"
)

for heading in "${required_headings[@]}"; do
  if ! grep -Fxq "$heading" docs/templates/machine-inventory.md; then
    echo "Missing machine inventory heading: $heading" >&2
    exit 1
  fi
done

if grep -RInE "(password|product key|recovery key|secret):[[:space:]]*[^[:space:]<]" README.md repo-state.md code_health.md docs scripts; then
  echo "Potential secret-like value found in tracked docs." >&2
  exit 1
fi

if grep -RInE "^(<<<<<<<|=======|>>>>>>>)" README.md repo-state.md code_health.md docs scripts .github; then
  echo "Unresolved merge marker found." >&2
  exit 1
fi

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoLogo -NoProfile -Command "[System.Management.Automation.Language.Parser]::ParseFile('scripts/Apply-Win10Minus.ps1', [ref]\$null, [ref]\$errors) | Out-Null; if (\$errors.Count -gt 0) { \$errors | ForEach-Object { Write-Error \$_ }; exit 1 }"
else
  echo "pwsh not found; skipping PowerShell parser validation."
fi

echo "windows-10-minus validation passed."
