"""Tests for catalogue.build_provides_index."""

from pathlib import Path

import pytest

from qemount_build.catalogue import build_output_index, build_provides_index, load


DATA_DIR = Path(__file__).parent / "data"


def test_build_provides_index_simple():
    """Index maps outputs to paths."""
    cat = load(DATA_DIR / "vars")
    ctx = {"HOST_ARCH": "x86_64", "ARCH": "x86_64"}

    index = build_provides_index(cat, ctx)

    assert index["output/x86_64/thing"] == "child"
    assert index["output/x86_64/leaf"] == "child/leaf"


def test_build_provides_index_different_arch():
    """Index changes with context."""
    cat = load(DATA_DIR / "vars")

    index_x86 = build_provides_index(cat, {"HOST_ARCH": "x86_64", "ARCH": "x86_64"})
    index_arm = build_provides_index(cat, {"HOST_ARCH": "aarch64", "ARCH": "aarch64"})

    assert "output/x86_64/thing" in index_x86
    assert "output/aarch64/thing" in index_arm
    assert "output/x86_64/thing" not in index_arm


def test_build_provides_index_duplicate_provider():
    """Duplicate providers raise ValueError."""
    cat = load(DATA_DIR / "deps")
    ctx = {}

    # Inject duplicate provider
    cat["paths"]["a"]["meta"]["provides"]["b-output"] = {}

    with pytest.raises(ValueError, match="Duplicate provider"):
        build_provides_index(cat, ctx)


def test_build_host_filter_propagates_to_dependents():
    cat = load(DATA_DIR / "deps")
    cat["paths"]["b"]["meta"]["build_hosts"] = {"x86_64": {}}
    ctx = {"HOST_ARCH": "aarch64", "ARCH": "aarch64"}

    outputs = build_output_index(cat, ctx)
    providers = build_provides_index(cat, ctx)

    assert outputs["root-output"]["buildable"]
    assert not outputs["b-output"]["buildable"]
    assert not outputs["a-output"]["buildable"]
    assert "host architecture aarch64" in outputs["b-output"]["reason"]
    assert "requires unavailable output b-output" in outputs["a-output"]["reason"]
    assert set(providers) == {"root-output"}
