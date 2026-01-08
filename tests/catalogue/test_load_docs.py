"""Tests for catalogue.load_docs."""

from pathlib import Path

from qemount_build.catalogue import load_docs


DATA_DIR = Path(__file__).parent / "data"


def test_load_finds_all_files():
    """load_docs finds all markdown files in tree."""
    docs = load_docs(DATA_DIR / "simple")
    assert "index.md" in docs
    assert "text.md" in docs
    assert "nested/README.md" in docs


def test_load_parses_frontmatter():
    """load_docs parses front-matter into meta dict."""
    docs = load_docs(DATA_DIR / "simple")
    assert docs["index.md"]["meta"]["type"] == "category"
    assert docs["nested/README.md"]["meta"]["type"] == "doc"


def test_load_no_frontmatter():
    """Files without front-matter have empty meta."""
    docs = load_docs(DATA_DIR / "simple")
    assert docs["text.md"]["meta"] == {}
    assert "Plain Text" in docs["text.md"]["content"]


def test_load_includes_hash():
    """Each doc has an md5 hash of file content."""
    docs = load_docs(DATA_DIR / "simple")
    for path, doc in docs.items():
        assert "hash" in doc
        assert len(doc["hash"]) == 32  # md5 hex length


def test_load_hash_value():
    """Hash matches expected value for text.md (no front-matter)."""
    docs = load_docs(DATA_DIR / "simple")
    assert docs["text.md"]["hash"] == "337dd4edeb087604f1c3c9e74c4b604a"
