from mountin.main import format_catalogue


def test_format_catalogue_excludes_unrelated_build_metadata():
    catalogue = {
        "files": {
            "docs/format/fs/ext4.md": {"meta": {"detect": []}},
            "bin/linux/9d/index.md": {"meta": {"requires": ["sources/9d"]}},
        },
        "paths": {
            "format/fs/ext4": {"meta": {"detect": []}},
            "bin/linux/9d": {"meta": {"requires": ["sources/9d"]}},
        },
    }

    assert format_catalogue(catalogue) == {
        "files": {"docs/format/fs/ext4.md": {"meta": {"detect": []}}},
        "paths": {"format/fs/ext4": {"meta": {"detect": []}}},
    }
