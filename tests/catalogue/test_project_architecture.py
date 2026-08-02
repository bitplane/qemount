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


def graph_for(target: str, context: dict = CONTEXT):
    with tempfile.TemporaryDirectory() as tmp:
        return build_graph(
            [target],
            project_catalogue(),
            context,
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


def test_fixed_arch_guests_resolve_on_arm_hosts():
    context = {
        "ARCH": "aarch64",
        "HOST_ARCH": "aarch64",
        "JOBS": "1",
    }
    providers = build_provides_index(project_catalogue(), context)

    assert providers["bin/i386-aros/simple9p"] == "bin/aros/simple9p"
    assert providers["bin/x86_64-darwin/simple9p"] == "bin/darwin/simple9p"

    aros = graph_for("bin/qemu/i386-aros/boot/aros.iso", context)
    darwin = graph_for(
        "bin/qemu/x86_64-darwin/puredarwin/appliance/puredarwin.raw",
        context,
    )

    assert "bin/aros/simple9p" in aros["nodes"]
    assert "bin/darwin/simple9p" in darwin["nodes"]


def test_linux_2_6_and_dependents_are_unavailable_on_arm_hosts():
    context = {
        "ARCH": "aarch64",
        "HOST_ARCH": "aarch64",
        "JOBS": "1",
    }
    providers = build_provides_index(project_catalogue(), context)

    assert "docker:builder/compiler/linux/2" not in providers
    assert "bin/qemu/aarch64-linux/2.6/kernel" not in providers
    assert "bin/qemu/aarch64-linux/2.6/boot/kernel" not in providers
    assert "data/fs/basic.reiserfs" not in providers
