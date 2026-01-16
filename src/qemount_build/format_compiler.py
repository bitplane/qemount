"""
Format detection rules compiler.

Extracts detection rules from docs/format/**/*.md frontmatter
and compiles them to msgpack for consumption by the Rust detection library.
"""

from pathlib import Path

import msgpack

from .catalogue import parse_frontmatter


def normalize_rule(rule: dict) -> dict:
    """Normalize a detection rule to standard form with defaults."""
    normalized = {
        "offset": rule.get("offset", 0),
        "type": rule["type"],
    }
    # value is optional for extraction-only rules (just name, no comparison)
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


def normalize_detect(detect) -> dict:
    """Normalize detect block to {all: [...]} or {any: [...]} form."""
    if isinstance(detect, list):
        return {"all": [normalize_rule(r) for r in detect]}
    if isinstance(detect, dict) and "any" in detect:
        return {"any": [normalize_rule(r) for r in detect["any"]]}
    # Single rule without list wrapper
    if isinstance(detect, dict) and "type" in detect:
        return {"all": [normalize_rule(detect)]}
    return {"all": []}


def compile_formats(root: Path) -> dict:
    """Extract detection rules from docs/format/**/*.md"""
    formats = {}
    format_dir = root / "docs" / "format"

    if not format_dir.exists():
        return {"version": 1, "formats": {}}

    for md_file in format_dir.rglob("*.md"):
        text = md_file.read_text()
        meta, _ = parse_frontmatter(text)

        if "detect" not in meta:
            continue

        # Path relative to format/, without .md, strip /index
        rel = md_file.relative_to(format_dir)
        key = str(rel.with_suffix(""))
        if key.endswith("/index"):
            key = key[:-6]
        if key == "index":
            continue  # Skip root index

        try:
            formats[key] = normalize_detect(meta["detect"])
        except (KeyError, TypeError) as e:
            raise ValueError(f"Error in {md_file}: {e}") from e

    return {"version": 1, "formats": formats}


def compile_to_file(root: Path, output: Path) -> int:
    """Compile formats and write to output file. Returns format count."""
    data = compile_formats(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(msgpack.packb(data))
    return len(data["formats"])
