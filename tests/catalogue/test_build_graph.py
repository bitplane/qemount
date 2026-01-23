"""Tests for catalogue.build_graph."""

import tempfile
from pathlib import Path

import pytest

from qemount_build.catalogue import load, build_graph, resolve_output, resolve_path


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


def test_resolve_output_inherits_from_path():
    """Output metadata inherits from catalogue path."""
    cat = load(DATA_DIR / "output_requires")
    ctx = {}

    # bin-linux has no output-specific metadata, inherits path requires
    meta = resolve_output("bin", "bin-linux", cat, ctx)
    assert "lib-common" in meta["requires"]
    assert "lib-win-extra" not in meta["requires"]


def test_resolve_output_merges_requires():
    """Output-specific requires merge with path requires."""
    cat = load(DATA_DIR / "output_requires")
    ctx = {}

    # bin-windows has output-specific requires that merge with path requires
    meta = resolve_output("bin", "bin-windows", cat, ctx)
    assert "lib-common" in meta["requires"]  # from path
    assert "lib-win-extra" in meta["requires"]  # from output


def test_resolve_output_no_metadata():
    """Output with no metadata returns path metadata unchanged."""
    cat = load(DATA_DIR / "output_requires")
    ctx = {}

    path_meta = resolve_path("lib", cat, ctx)
    output_meta = resolve_output("lib", "lib-common", cat, ctx)

    assert path_meta == output_meta


def test_build_graph_output_specific_requires():
    """Graph includes output-specific dependencies."""
    cat = load(DATA_DIR / "output_requires")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        # bin-windows needs lib-common (path) + lib-win-extra (output-specific)
        graph = build_graph(["bin-windows"], cat, ctx, Path(tmp))

    assert "lib" in graph["nodes"]
    assert "lib-win" in graph["nodes"]
    assert "lib-win-extra" in graph["needed"]["lib-win"]


def test_build_graph_output_without_specific_requires():
    """Graph excludes deps not needed by specific output."""
    cat = load(DATA_DIR / "output_requires")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        # bin-linux only needs lib-common, not lib-win-extra
        graph = build_graph(["bin-linux"], cat, ctx, Path(tmp))

    assert "lib" in graph["nodes"]
    assert "lib-win" not in graph["nodes"]  # not needed for linux


def test_build_graph_multiple_outputs_same_path():
    """Building multiple outputs from same path includes all deps."""
    cat = load(DATA_DIR / "output_requires")
    ctx = {}

    with tempfile.TemporaryDirectory() as tmp:
        # Both outputs from bin - should include both dep chains
        graph = build_graph(["bin-linux", "bin-windows"], cat, ctx, Path(tmp))

    assert "lib" in graph["nodes"]
    assert "lib-win" in graph["nodes"]
    assert {"bin-linux", "bin-windows"} == graph["needed"]["bin"]


def test_build_graph_file_dependency_in_build_dir():
    """File dependencies in build_dir are allowed without catalogue entry."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    # Add a requires for a file that doesn't have a provider
    cat["paths"]["a"]["meta"]["requires"]["external-file.bin"] = {}

    with tempfile.TemporaryDirectory() as tmp:
        # Create the file in build_dir
        (Path(tmp) / "external-file.bin").write_bytes(b"data")

        # Should succeed - file exists in build_dir
        graph = build_graph(["a-output"], cat, ctx, Path(tmp))

    assert "a" in graph["nodes"]
