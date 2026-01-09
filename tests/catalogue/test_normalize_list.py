"""Tests for catalogue.normalize_list."""

from qemount_build.catalogue import normalize_list


def test_strings_become_keys():
    """String items become keys with empty dict values."""
    result = normalize_list(["a", "b", "c"])
    assert result == {"a": {}, "b": {}, "c": {}}


def test_dicts_merged():
    """Dict items are merged into result."""
    result = normalize_list([{"a": {"x": 1}}, {"b": {"y": 2}}])
    assert result == {"a": {"x": 1}, "b": {"y": 2}}


def test_mixed():
    """Mixed strings and dicts."""
    result = normalize_list([
        "format/fs/ext4",
        {"format/fs/ntfs": {"write": False}},
        "format/fs/zfs",
    ])
    assert result == {
        "format/fs/ext4": {},
        "format/fs/ntfs": {"write": False},
        "format/fs/zfs": {},
    }


def test_empty():
    """Empty list returns empty dict."""
    assert normalize_list([]) == {}


def test_dict_overwrites_string():
    """Later dict entry overwrites earlier string entry."""
    result = normalize_list([
        "a",
        {"a": {"value": 1}},
    ])
    assert result == {"a": {"value": 1}}
