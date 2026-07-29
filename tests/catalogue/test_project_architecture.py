"""Architecture invariants for the real project catalogue."""

import tempfile
from pathlib import Path

from qemount_build.catalogue import build_graph, build_provides_index, load


PACKAGE_DIR = Path(__file__).parents[2] / "src" / "qemount_build"
CONTEXT = {
    "ARCH": "x86_64",
    "HOST_ARCH": "x86_64",
    "JOBS": "1",
}


def project_catalogue():
    return load(PACKAGE_DIR)


def graph_for(target: str):
    with tempfile.TemporaryDirectory() as tmp:
        return build_graph(
            [target],
            project_catalogue(),
            CONTEXT,
            Path(tmp),
        )


def test_amiga_manifest_has_separate_provider_from_generic_template():
    providers = build_provides_index(project_catalogue(), CONTEXT)

    assert providers["data/templates/basic.tar"] == "data/templates"
    assert providers["data/templates/basic.amiga"] == "data/templates/amiga"


def test_only_amiga_fixtures_depend_on_amiga_manifest():
    for target in (
        "data/fs/basic.amiga-pfs",
        "data/fs/basic.amiga-sfs",
    ):
        assert "data/templates/amiga" in graph_for(target)["nodes"]

    for target in (
        "data/arc/basic.zip",
        "data/fs/basic.ext4",
    ):
        assert "data/templates/amiga" not in graph_for(target)["nodes"]
