#!/usr/bin/env python3
"""
Format detection rules compiler.

Reads catalogue.json, extracts detection rules from format/* entries,
and writes them to format.bin as msgpack.

Usage: python compile.py catalogue.json format.bin
"""

import json
import sys

import msgpack


def normalize_rule(rule: dict) -> dict:
    """Normalize a detection rule to standard form with defaults."""
    normalized = {
        "offset": rule.get("offset", 0),
        "type": rule["type"],
    }
    if "value" in rule:
        normalized["value"] = rule["value"]
    if "name" in rule:
        normalized["name"] = rule["name"]
    if "op" in rule:
        normalized["op"] = rule["op"]
    if "mask" in rule:
        normalized["mask"] = rule["mask"]
    if "then" in rule:
        normalized["then"] = [normalize_rule(r) for r in rule["then"]]
    return normalized


def normalize_detect(detect) -> dict | None:
    """Normalize detect block to {all: [...]} or {any: [...]} form.

    Returns None if no valid rules (empty list, comments only, etc).
    """
    if isinstance(detect, list):
        rules = [normalize_rule(r) for r in detect]
        return {"all": rules} if rules else None
    if isinstance(detect, dict) and "any" in detect:
        rules = [normalize_rule(r) for r in detect["any"]]
        return {"any": rules} if rules else None
    if isinstance(detect, dict) and "type" in detect:
        return {"all": [normalize_rule(detect)]}
    return None


def compile_formats(catalogue: dict) -> dict:
    """Extract detection rules from catalogue paths under format/"""
    formats = {}
    paths = catalogue.get("paths", {})

    for path, data in paths.items():
        if not path.startswith("format/"):
            continue

        meta = data.get("meta", {})
        if "detect" not in meta:
            continue

        # Strip "format/" prefix for key
        key = path[7:]
        if not key:
            continue

        try:
            result = normalize_detect(meta["detect"])
            if result is not None:
                formats[key] = result
        except (KeyError, TypeError) as e:
            raise ValueError(f"Error in {path}: {e}") from e

    return {"version": 1, "formats": formats}


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} catalogue.json format.bin", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1]) as f:
        catalogue = json.load(f)

    data = compile_formats(catalogue)

    with open(sys.argv[2], "wb") as f:
        f.write(msgpack.packb(data))

    print(f"Wrote {len(data['formats'])} formats to {sys.argv[2]}")


if __name__ == "__main__":
    main()
