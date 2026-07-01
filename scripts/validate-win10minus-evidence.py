#!/usr/bin/env python3
"""Validate Windows 10 Minus evidence JSON files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def is_bool(value: Any) -> bool:
    return isinstance(value, bool)


def is_str(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def require_object(label: str, value: Any, errors: list[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        errors.append(f"{label} must be an object")
        return {}
    return value


def require_list(label: str, value: Any, errors: list[str]) -> list[Any]:
    if not isinstance(value, list):
        errors.append(f"{label} must be a list")
        return []
    return value


def validate(path: Path) -> dict[str, object]:
    errors: list[str] = []
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        return {
            "schema": "win10minus-evidence-validation/v1",
            "status": "failed",
            "evidence": str(path),
            "errors": [f"unable to read evidence JSON: {exc}"],
        }

    if not isinstance(raw, dict):
        return {
            "schema": "win10minus-evidence-validation/v1",
            "status": "failed",
            "evidence": str(path),
            "errors": ["evidence root must be an object"],
        }

    evidence = raw
    if not is_str(evidence.get("timestamp")):
        errors.append("timestamp is required")
    if not is_str(evidence.get("hostname")):
        errors.append("hostname is required")

    if "profile" in evidence and evidence["profile"] is not None and not is_str(evidence["profile"]):
        errors.append("profile must be a string when present")

    powershell = require_object("powershell", evidence.get("powershell"), errors)
    if powershell and ("version" in powershell and not is_str(powershell.get("version"))):
        errors.append("powershell.version must be a non-empty string when present")

    os_block = require_object("os", evidence.get("os"), errors)
    if os_block and not is_str(os_block.get("os_name")):
        errors.append("os.os_name must be a non-empty string")
    if os_block and not is_str(os_block.get("os_version")):
        errors.append("os.os_version must be a non-empty string")

    services = require_object("services", evidence.get("services"), errors)
    if services:
        for name, svc in services.items():
            if not isinstance(svc, dict):
                errors.append(f"services[{name}] must be an object")
                continue
            status = svc.get("status")
            start_type = svc.get("start_type")
            if status is not None and not is_str(status):
                errors.append(f"services[{name}].status must be a string")
            if start_type is not None and not is_str(start_type):
                errors.append(f"services[{name}].start_type must be a string")

    appx = require_object("appx", evidence.get("appx"), errors)
    if appx:
        if "store_present" not in appx:
            errors.append("appx.store_present is required")
        elif not is_bool(appx.get("store_present")):
            errors.append("appx.store_present must be a boolean")

    hardware = require_object("hardware", evidence.get("hardware"), errors)
    if hardware:
        for field in ("audio_devices", "capture_devices", "display_controllers"):
            if field in hardware:
                require_list(f"hardware.{field}", hardware[field], errors)

    scripts_block = require_object("scripts", evidence.get("scripts"), errors)
    if scripts_block:
        if not is_str(scripts_block.get("profile_log_path")):
            errors.append("scripts.profile_log_path is required")
        if "profile_log_exists" in scripts_block and not is_bool(scripts_block.get("profile_log_exists")):
            errors.append("scripts.profile_log_exists must be a boolean")
        if "profile_log_file_count" in scripts_block and not isinstance(scripts_block.get("profile_log_file_count"), int):
            errors.append("scripts.profile_log_file_count must be an integer")

    checks = require_object("checks", evidence.get("checks"), errors)
    if checks:
        for key in (
            "store_open_hint",
            "start_menu_hint",
            "browser_hint",
            "defender_hint",
            "update_hint",
            "windows_update_hint",
        ):
            if key in checks and not is_str(checks[key]):
                errors.append(f"checks.{key} must be a non-empty string")

    if "errors" in evidence and not isinstance(evidence["errors"], list):
        errors.append("errors must be a list")

    return {
        "schema": "win10minus-evidence-validation/v1",
        "status": "ok" if not errors else "failed",
        "evidence": str(path),
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Windows 10 Minus evidence JSON.")
    parser.add_argument("paths", nargs="*", help="Evidence JSON path(s).")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output.")
    args = parser.parse_args()

    if not args.paths:
        parser.print_usage()
        print("error: at least one evidence path is required", file=sys.stderr)
        return 1

    any_failed = False
    results: list[dict[str, object]] = []
    for raw_path in args.paths:
        result = validate(Path(raw_path))
        if result["status"] != "ok":
            any_failed = True
        results.append(result)

    if len(results) == 1:
        print(json.dumps(results[0], indent=2 if args.pretty else None, sort_keys=True))
    else:
        print(json.dumps({"schema": "win10minus-evidence-validation/batch/v1", "results": results}, indent=2 if args.pretty else None, sort_keys=True))

    return 1 if any_failed else 0


if __name__ == "__main__":
    sys.exit(main())
