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


def normalize_rule(rule, path: list[str] | None = None) -> dict:
    """Normalize a detection rule to standard form with defaults."""
    path = path or []

    if not isinstance(rule, dict):
        raise TypeError(f"Expected dict, got {type(rule).__name__}: {rule!r} at {'/'.join(path) or 'root'}")

    # Handle any/all blocks (not actual rules, just containers)
    if "any" in rule:
        return {"any": [normalize_rule(r, path + [f"any[{i}]"]) for i, r in enumerate(rule["any"])]}
    if "all" in rule:
        return {"all": [normalize_rule(r, path + [f"all[{i}]"]) for i, r in enumerate(rule["all"])]}

    if "type" not in rule:
        raise KeyError(f"Missing 'type' in rule at {'/'.join(path) or 'root'}: {rule!r}")

    normalized = {
        "offset": rule.get("offset", 0),
        "type": rule["type"],
    }
    if "value" in rule:
        value = rule["value"]
        # For string type, encode as list of byte values
        # (avoids msgpack binary type issues with serde untagged enums)
        # For ascii type, keep as string (used as regex pattern)
        if rule["type"] == "string" and isinstance(value, str):
            value = list(value.encode("latin-1"))
        normalized["value"] = value
    if "length" in rule:
        normalized["length"] = rule["length"]
    if "name" in rule:
        normalized["name"] = rule["name"]
    if "op" in rule:
        normalized["op"] = rule["op"]
    if "mask" in rule:
        normalized["mask"] = rule["mask"]
    if "algorithm" in rule:
        normalized["algorithm"] = rule["algorithm"]
    if "key" in rule:
        normalized["key"] = rule["key"]
    if "then" in rule:
        normalized["then"] = [normalize_rule(r, path + [f"then[{i}]"]) for i, r in enumerate(rule["then"])]
    return normalized


def normalize_detect(detect) -> dict | None:
    """Normalize detect block to {all: [...]} or {any: [...]} form.

    Returns None if no valid rules (empty list, comments only, etc).
    """
    if isinstance(detect, list):
        rules = [normalize_rule(r, [f"detect[{i}]"]) for i, r in enumerate(detect)]
        return {"all": rules} if rules else None
    if isinstance(detect, dict) and "all" in detect:
        rules = [normalize_rule(r, [f"detect/all[{i}]"]) for i, r in enumerate(detect["all"])]
        return {"all": rules} if rules else None
    if isinstance(detect, dict) and "any" in detect:
        rules = [normalize_rule(r, [f"detect/any[{i}]"]) for i, r in enumerate(detect["any"])]
        return {"any": rules} if rules else None
    if isinstance(detect, dict) and "type" in detect:
        return {"all": [normalize_rule(detect, ["detect"])]}
    return None


def compile_formats(catalogue: dict) -> dict:
    """Extract detection rules from catalogue paths under format/"""
    formats = []
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
                priority = meta.get("priority", 0)
                formats.append((key, result, priority))
        except (KeyError, TypeError) as e:
            raise ValueError(f"Error in {path}: {e}") from e

    # Sort by priority (descending), then name for deterministic output
    formats.sort(key=lambda x: (-x[2], x[0]))
    return {"version": 1, "formats": {k: v for k, v, _ in formats}}


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
