import json

from mountin.cache import save_cache, update_output_hash
from mountin.inventory import create_inventory, write_inventory


def catalogue():
    return {
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


def context():
    return {
        "MOUNTIN_BUILD_PLATFORM": "x86_64-linux",
        "MOUNTIN_BUILD_ARCH": "x86_64",
        "MOUNTIN_BUILD_OS": "linux",
    }


def test_inventory_records_present_cross_platform_artefacts(tmp_path):
    x86 = "bin/x86_64-linux-musl/tool"
    arm = "bin/aarch64-linux-musl/tool"
    for output in (x86, arm):
        path = tmp_path / output
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(output)

    cache = {}
    update_output_hash(
        cache,
        x86,
        "x86-input",
        tmp_path,
        provenance={"build_platform": "x86_64-linux"},
    )
    update_output_hash(
        cache,
        arm,
        "arm-input",
        tmp_path,
        provenance={"build_platform": "aarch64-linux"},
    )
    save_cache(tmp_path, cache)

    inventory, unknown = create_inventory(catalogue(), context(), tmp_path)

    assert unknown == []
    assert {item["path"] for item in inventory["artefacts"]} == {x86, arm}
    assert {item["build_platform"] for item in inventory["artefacts"]} == {
        "x86_64-linux",
        "aarch64-linux",
    }


def test_inventory_reports_unknown_files_and_writes_atomically(tmp_path):
    unknown_path = tmp_path / "data/untracked.img"
    unknown_path.parent.mkdir(parents=True)
    unknown_path.write_bytes(b"unknown")

    inventory, unknown = create_inventory(catalogue(), context(), tmp_path)
    destination = tmp_path / "inventory.json"
    write_inventory(inventory, destination)

    assert unknown == ["data/untracked.img"]
    assert json.loads(destination.read_text())["schema"] == 1
    assert not (tmp_path / "inventory.json.tmp").exists()
