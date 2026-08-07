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


def test_mbr_detection_allows_boot_code_jump():
    compiled = compile_formats(load(PACKAGE_DIR))
    detect = compiled["formats"]["pt/mbr"]

    assert detect == {
        "all": [
            {
                "offset": 510,
                "type": "le16",
                "value": 0xAA55,
                "then": [
                    {
                        "any": [
                            {"offset": offset, "type": "byte", "op": "!=", "value": 0}
                            for offset in (450, 466, 482, 498)
                        ]
                    }
                ],
            }
        ]
    }


def test_plan9_detection_uses_ascii_partition_table():
    compiled = compile_formats(load(PACKAGE_DIR))

    assert compiled["formats"]["pt/plan9"] == {
        "all": [
            {
                "offset": 0x200,
                "type": "string",
                "length": 5,
                "value": [ord(character) for character in "part "],
            }
        ]
    }
