from qemount_build.gc import abandoned_work_directories, parse_obsolete_images


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
