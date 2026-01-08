"""Tests for catalogue.parse_frontmatter."""

from qemount_build.catalogue import parse_frontmatter


def test_no_frontmatter():
    """Plain markdown with no front-matter returns empty meta."""
    text = "# Hello\n\nSome content."
    meta, content = parse_frontmatter(text)
    assert meta == {}
    assert content == "# Hello\n\nSome content."


def test_simple_frontmatter():
    """Basic YAML front-matter is parsed."""
    text = """---
type: category
title: Test
---

# Content here
"""
    meta, content = parse_frontmatter(text)
    assert meta == {"type": "category", "title": "Test"}
    assert content == "# Content here\n"


def test_frontmatter_with_list():
    """Front-matter containing lists."""
    text = """---
type: guest
support:
  - fs/ext4
  - fs/btrfs
---

# Guest
"""
    meta, content = parse_frontmatter(text)
    assert meta["type"] == "guest"
    assert meta["support"] == ["fs/ext4", "fs/btrfs"]


def test_frontmatter_with_nested_dict():
    """Front-matter containing nested dicts."""
    text = """---
outputs:
  vmlinuz:
    url: https://example.com/vmlinuz
---

# Builder
"""
    meta, content = parse_frontmatter(text)
    assert meta["outputs"]["vmlinuz"]["url"] == "https://example.com/vmlinuz"


def test_empty_frontmatter():
    """Empty front-matter block returns empty dict."""
    text = """---
---

# Content
"""
    meta, content = parse_frontmatter(text)
    assert meta == {}
    assert content == "# Content\n"


def test_unclosed_frontmatter():
    """Unclosed front-matter returns full text as content."""
    text = """---
type: broken
# No closing ---

Content here.
"""
    meta, content = parse_frontmatter(text)
    assert meta == {}
    assert "type: broken" in content


def test_frontmatter_not_at_start():
    """Front-matter must be at start of file."""
    text = """
---
type: test
---

# Content
"""
    meta, content = parse_frontmatter(text)
    assert meta == {}
    assert "type: test" in content
