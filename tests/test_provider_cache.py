from qemount_build.provider_cache import (
    provider_cache_container,
    provider_cache_name,
    provider_cache_relative,
)


def test_provider_cache_name_is_readable_stable_and_tool_safe():
    name = provider_cache_name("bin/example@x86_64-test")

    assert name.startswith("bin-example-x86_64-test--")
    assert len(name.rsplit("--", 1)[1]) == 24
    assert "%" not in name
    assert provider_cache_name("") == "_root"


def test_provider_cache_name_hash_prevents_slug_collisions():
    assert provider_cache_name("bin/a/b") != provider_cache_name("bin/a-b")


def test_provider_cache_paths_include_the_build_platform():
    assert str(
        provider_cache_relative("aarch64-linux", "bin/example@x86_64-test")
    ).startswith("stages/aarch64-linux/bin-example-x86_64-test--")
    assert provider_cache_container(
        "aarch64-linux", "bin/example@x86_64-test"
    ).startswith(
        "/host/build/cache/stages/aarch64-linux/bin-example-x86_64-test--"
    )
