from qemount_build.gc import (
    orphaned_provider_caches,
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


def test_orphaned_provider_caches_preserve_live_names_on_every_build_platform(tmp_path):
    stages = tmp_path / "cache/stages"
    live_x86 = stages / "x86_64-linux/live"
    live_arm = stages / "aarch64-linux/live"
    orphan = stages / "x86_64-linux/orphan"
    for path in (live_x86, live_arm, orphan):
        path.mkdir(parents=True)

    assert orphaned_provider_caches(tmp_path, {"live"}) == [orphan]
