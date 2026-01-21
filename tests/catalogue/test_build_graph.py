"""Tests for catalogue.build_graph."""

import tempfile
from pathlib import Path

import pytest

from qemount_build.catalogue import load, build_graph


DATA_DIR = Path(__file__).parent / "data"


def test_build_graph_simple_chain():
    """Graph follows dependency chain."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        graph = build_graph(["a-output"], cat, ctx, Path(tmp))

    assert graph["targets"] == ["a"]
    assert graph["order"] == ["", "b", "a"]  # root, b, a (deps first)


def test_build_graph_edges():
    """Edges connect dependents to dependencies."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        graph = build_graph(["a-output"], cat, ctx, Path(tmp))

    assert ("a", "b") in graph["edges"]
    assert ("b", "") in graph["edges"]


def test_build_graph_nodes_have_meta():
    """Nodes contain resolved metadata."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        graph = build_graph(["a-output"], cat, ctx, Path(tmp))

    assert graph["nodes"]["a"]["title"] == "A"
    assert graph["nodes"]["b"]["title"] == "B"


def test_build_graph_missing_target():
    """Missing target raises KeyError."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        with pytest.raises(KeyError, match="No provider for target"):
            build_graph(["nonexistent"], cat, ctx, Path(tmp))


def test_build_graph_missing_dependency():
    """Missing dependency raises KeyError with context."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    # Remove root's provides to break the chain
    cat["paths"][""]["meta"]["provides"] = {}

    with tempfile.TemporaryDirectory() as tmp:
        with pytest.raises(KeyError, match="No provider for.*required by"):
            build_graph(["a-output"], cat, ctx, Path(tmp))


def test_build_graph_cycle():
    """Cycle in dependencies raises ValueError."""
    cat = load(DATA_DIR / "cycle")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        with pytest.raises(ValueError, match="Dependency cycle"):
            build_graph(["x-output"], cat, ctx, Path(tmp))
