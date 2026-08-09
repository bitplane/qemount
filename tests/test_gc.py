import json

from qemount_build.gc import (
    CACHE_GENERATION_MARKER,
    abandoned_work_directories,
    obsolete_cache_generations,
    parse_obsolete_images,
)


def test_parse_obsolete_images_selects_only_unique_untagged_images():
    lines = [
        "aaaa\t<none>\t<none>",
        "bbbb\tlocalhost/example\tlatest",
        "aaaa\t<none>\t<none>",
        "cccc\tlocalhost/example\t<none>",
    ]

    assert parse_obsolete_images(lines) == ["aaaa"]


def test_abandoned_work_directories_are_scoped_to_9front_cache(tmp_path):
    abandoned = tmp_path / "cache/9front/host/arch/version/run.abcd"
    abandoned.mkdir(parents=True)
    unrelated = tmp_path / "cache/other/run.efgh"
    unrelated.mkdir(parents=True)

    assert abandoned_work_directories(tmp_path) == [abandoned]


def register_cache(tmp_path, owner, current):
    cache = tmp_path / "cache"
    root = cache / "example/host/target/compiler-v1"
    for generation in ("old", current, "unowned"):
        (root / generation).mkdir(parents=True)
    (root / "old" / CACHE_GENERATION_MARKER).write_text(owner)
    (root / current / CACHE_GENERATION_MARKER).write_text(owner)
    manifests = cache / ".qemount/manifests"
    manifests.mkdir(parents=True)
    (manifests / "example.json").write_text(
        json.dumps(
            {
                "schema": 1,
                "owner": owner,
                "root": "example/host/target/compiler-v1",
                "current": current,
            }
        )
    )
    return root


def test_obsolete_cache_generations_require_matching_manifest_and_marker(tmp_path):
    root = register_cache(tmp_path, "example/compiler", "current")

    assert obsolete_cache_generations(tmp_path) == [root / "old"]


def test_invalid_cache_manifest_is_ignored(tmp_path, caplog):
    root = register_cache(tmp_path, "example/compiler", "missing")
    (root / "missing" / CACHE_GENERATION_MARKER).unlink()
    (root / "missing").rmdir()

    assert obsolete_cache_generations(tmp_path) == []
    assert "Ignoring invalid cache manifest" in caplog.text
