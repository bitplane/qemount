"""Detection-rule invariants for formats exercised by project fixtures."""

from pathlib import Path

from qemount_build.catalogue import load
from qemount_build.lib.format.compile import compile_formats


PACKAGE_DIR = Path(__file__).parents[2] / "src" / "qemount_build"


def test_sfs_versions_are_alternatives():
    compiled = compile_formats(load(PACKAGE_DIR))
    detect = compiled["formats"]["fs/amiga-sfs"]

    assert "any" in detect
    assert [rule["value"] for rule in detect["any"]] == [
        [ord("S"), ord("F"), ord("S"), 0],
        [ord("S"), ord("F"), ord("S"), 2],
    ]
