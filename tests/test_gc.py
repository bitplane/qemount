from qemount_build.gc import (
    orphaned_provider_caches,
    parse_obsolete_images,
    remove_obsolete_images,
)
from qemount_build.provider_cache import remove_provider_cache


def test_parse_obsolete_images_selects_only_unique_untagged_images():
    lines = [
        "aaaa\t<none>\t<none>",
        "bbbb\tlocalhost/example\tlatest",
        "aaaa\t<none>\t<none>",
        "cccc\tlocalhost/example\t<none>",
    ]

    assert parse_obsolete_images(lines) == ["aaaa"]


def test_remove_obsolete_images_skips_images_retained_by_containers(monkeypatch):
    commands = []

    class Result:
        def __init__(self, returncode, stderr=""):
            self.returncode = returncode
            self.stdout = ""
            self.stderr = stderr

    def remove(command, **kwargs):
        commands.append(command)
        if command[-1] == "retained":
            return Result(1, "image is in use by a container")
        return Result(0)

    monkeypatch.setattr("qemount_build.gc.subprocess.run", remove)

    assert remove_obsolete_images(["unused", "retained"]) == 1
    assert commands == [
        ["podman", "image", "rm", "unused"],
        ["podman", "image", "rm", "retained"],
    ]


def test_orphaned_provider_caches_preserve_live_names_on_every_build_platform(tmp_path):
    stages = tmp_path / "cache/stages"
    live_x86 = stages / "x86_64-linux/live"
    live_arm = stages / "aarch64-linux/live"
    orphan = stages / "x86_64-linux/orphan"
    for path in (live_x86, live_arm, orphan):
        path.mkdir(parents=True)

    assert orphaned_provider_caches(tmp_path, {"live"}) == [orphan]


def test_remove_provider_cache_uses_podman_user_namespace(tmp_path, monkeypatch):
    cache = tmp_path / "cache/stages/x86_64-linux/orphan"
    cache.mkdir(parents=True)
    commands = []

    def deny(_path):
        raise PermissionError

    def remove(command, check):
        commands.append(command)
        cache.rmdir()
        return type("Result", (), {"returncode": 0})()

    monkeypatch.setattr("qemount_build.provider_cache.shutil.rmtree", deny)
    monkeypatch.setattr("qemount_build.provider_cache.subprocess.run", remove)

    remove_provider_cache(tmp_path, cache)

    assert commands == [
        ["podman", "unshare", "rm", "-rf", "--", str(cache.absolute())]
    ]
