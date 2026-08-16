"""Tests for catalogue.build_provides_index."""

from pathlib import Path

import pytest

from mountin.catalogue import build_output_index, build_provides_index, load


DATA_DIR = Path(__file__).parent / "data"


def test_build_provides_index_simple():
    """Index maps outputs to paths."""
    cat = load(DATA_DIR / "vars")
    ctx = {"BUILD_ARCH": "x86_64", "OUTPUT_ARCH": "x86_64"}

    index = build_provides_index(cat, ctx)

    assert index["output/x86_64/thing"] == "child"
    assert index["output/x86_64/leaf"] == "child/leaf"


def test_build_provides_index_enumerates_platforms_independently_of_build_host():
    cat = load(DATA_DIR / "vars")

    index_x86 = build_provides_index(cat, {"BUILD_ARCH": "x86_64", "OUTPUT_ARCH": "x86_64"})
    index_arm = build_provides_index(cat, {"BUILD_ARCH": "aarch64", "OUTPUT_ARCH": "aarch64"})

    assert "output/x86_64/thing" in index_x86
    assert "output/aarch64/thing" in index_x86
    assert "output/x86_64/thing" in index_arm
    assert "output/aarch64/thing" in index_arm


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
    cat["paths"]["b"]["meta"]["build_platforms"] = {"x86_64-linux": {}}
    ctx = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
    }

    outputs = build_output_index(cat, ctx)
    providers = build_provides_index(cat, ctx)

    assert outputs["root-output"]["buildable"]
    assert not outputs["b-output"]["buildable"]
    assert not outputs["a-output"]["buildable"]
    assert "build platform aarch64-linux" in outputs["b-output"]["reason"]
    assert "requires unavailable output b-output" in outputs["a-output"]["reason"]
    assert set(providers) == {"root-output"}


def test_same_provider_expands_to_distinct_platform_instances():
    cat = {
        "paths": {
            "tool": {
                "sources": ["tool/index.md"],
                "meta": {
                    "output_platforms": {
                        "x86_64-linux-musl": {
                            "provides": ["bin/x86_64-linux-musl/tool"]
                        },
                        "aarch64-linux-musl": {
                            "provides": ["bin/aarch64-linux-musl/tool"]
                        },
                    }
                },
            }
        }
    }
    context = {
        "BUILD_PLATFORM": "x86_64-linux",
        "BUILD_ARCH": "x86_64",
        "BUILD_OS": "linux",
    }
    outputs = build_output_index(cat, context)

    assert outputs["bin/x86_64-linux-musl/tool"]["id"] == (
        "tool@x86_64-linux-musl"
    )
    assert outputs["bin/aarch64-linux-musl/tool"]["id"] == (
        "tool@aarch64-linux-musl"
    )


def test_build_output_index_honours_source_kind():
    cat = {
        "paths": {
            "release": {
                "meta": {
                    "source_kinds": {"checkout": {}},
                    "provides": {"release/package": {}},
                },
                "sources": [],
            }
        }
    }

    checkout = build_output_index(
        cat, {"BUILD_PLATFORM": "x86_64-linux", "SOURCE_KIND": "checkout"}
    )
    distribution = build_output_index(
        cat, {"BUILD_PLATFORM": "x86_64-linux", "SOURCE_KIND": "distribution"}
    )

    assert checkout["release/package"]["buildable"]
    assert not distribution["release/package"]["buildable"]
    assert "source kind distribution" in distribution["release/package"]["reason"]
