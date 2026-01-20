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
