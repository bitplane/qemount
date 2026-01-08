"""
Catalogue loader for qemount build system.

Loads all markdown files from a directory tree, parsing YAML front-matter
into a flat dict keyed by relative path.
"""

from pathlib import Path

import yaml


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """
    Parse YAML front-matter from markdown text.

    Returns (meta, content) tuple. If no front-matter found,
    returns empty dict and full text.
    """
    if not text.startswith("---"):
        return {}, text

    # Find closing ---
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text

    yaml_text = text[4:end]  # Skip opening ---\n
    content = text[end + 4:].lstrip("\n")  # Skip closing ---\n

    meta = yaml.safe_load(yaml_text) or {}
    return meta, content


def load(root: Path) -> dict:
    """
    Load all markdown files from root directory into a catalogue.

    Returns dict mapping relative paths to {"meta": dict, "content": str}.
    """
    root = Path(root)
    docs = {}

    for md_file in root.rglob("*.md"):
        rel_path = str(md_file.relative_to(root))
        text = md_file.read_text()
        meta, content = parse_frontmatter(text)
        docs[rel_path] = {"meta": meta, "content": content}

    return docs
