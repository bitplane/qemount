"""
Catalogue loader for qemount build system.

Loads all markdown files from a directory tree, parsing YAML front-matter
into a flat dict keyed by relative path.
"""

import hashlib
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


def load_docs(root: Path) -> dict:
    """
    Load all markdown files from root directory into a catalogue.

    Returns dict mapping relative paths to {"meta": dict, "content": str, "hash": str}.
    Hash is md5 of raw file content for cache invalidation.
    """
    root = Path(root)
    docs = {}

    for md_file in root.rglob("*.md"):
        rel_path = str(md_file.relative_to(root))
        raw = md_file.read_bytes()
        file_hash = hashlib.md5(raw).hexdigest()
        text = raw.decode("utf-8")
        meta, content = parse_frontmatter(text)
        docs[rel_path] = {"meta": meta, "content": content, "hash": file_hash}

    return docs
