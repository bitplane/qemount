from qemount_build.provider_cache import (
    provider_cache_container,
    provider_cache_name,
    provider_cache_relative,
)


def test_provider_cache_name_encodes_the_complete_instance():
    assert provider_cache_name("bin/example@x86_64-test") == (
        "bin%2Fexample%40x86_64-test"
    )
    assert provider_cache_name("") == "_root"


def test_provider_cache_paths_include_the_build_platform():
    assert str(
        provider_cache_relative("aarch64-linux", "bin/example@x86_64-test")
    ) == "stages/aarch64-linux/bin%2Fexample%40x86_64-test"
    assert provider_cache_container(
        "aarch64-linux", "bin/example@x86_64-test"
    ) == "/host/build/cache/stages/aarch64-linux/bin%2Fexample%40x86_64-test"
