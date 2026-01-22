"""Tests for catalogue.merge_meta."""

from qemount_build.catalogue import merge_meta


def test_child_extends_parent():
    """Child adds new keys to parent."""
    parent = {"a": 1}
    child = {"b": 2}
    result = merge_meta(parent, child)
    assert result == {"a": 1, "b": 2}


def test_child_overwrites_parent():
    """Child values overwrite parent values."""
    parent = {"a": 1}
    child = {"a": 2}
    result = merge_meta(parent, child)
    assert result == {"a": 2}


def test_deletion():
    """Keys prefixed with - are deleted from parent."""
    parent = {"a": 1, "b": 2, "c": 3}
    child = {"-b": None}
    result = merge_meta(parent, child)
    assert result == {"a": 1, "c": 3}


def test_deep_merge():
    """Nested dicts are merged recursively."""
    parent = {"outer": {"a": 1, "b": 2}}
    child = {"outer": {"b": 3, "c": 4}}
    result = merge_meta(parent, child)
    assert result == {"outer": {"a": 1, "b": 3, "c": 4}}


def test_list_normalized():
    """Lists are normalized to dicts before merging."""
    parent = {"supports": ["a", "b"]}
    child = {"supports": ["c"]}
    result = merge_meta(parent, child)
    assert result == {"supports": {"a": {}, "b": {}, "c": {}}}


def test_list_deletion():
    """Can delete items from normalized list."""
    parent = {"supports": ["a", "b", "c"]}
    child = {"supports": ["-b"]}
    result = merge_meta(parent, child)
    assert result == {"supports": {"a": {}, "c": {}}}


def test_list_with_properties():
    """List items with properties merge correctly."""
    parent = {"supports": ["a", {"b": {"write": True}}]}
    child = {"supports": [{"b": {"write": False}}, "c"]}
    result = merge_meta(parent, child)
    assert result == {"supports": {"a": {}, "b": {"write": False}, "c": {}}}


def test_empty_parent():
    """Empty parent returns child."""
    result = merge_meta({}, {"a": 1})
    assert result == {"a": 1}


def test_empty_child():
    """Empty child returns parent."""
    result = merge_meta({"a": 1}, {})
    assert result == {"a": 1}


def test_both_empty():
    """Empty parent and child returns empty."""
    result = merge_meta({}, {})
    assert result == {}


def test_no_inherit_prevents_parent_copy():
    """Keys in no_inherit are not copied from parent."""
    parent = {"a": 1, "provides": ["x", "y"]}
    child = {"b": 2}
    result = merge_meta(parent, child, no_inherit={"provides"})
    assert result == {"a": 1, "b": 2}
    assert "provides" not in result


def test_no_merge_overrides_completely():
    """Keys in no_merge override parent entirely, no deep merge."""
    parent = {"detect": {"offset": 0, "type": "byte"}}
    child = {"detect": {"offset": 512, "type": "string"}}
    result = merge_meta(parent, child, no_merge={"detect"})
    # Child detect should completely replace parent, not merge
    assert result["detect"] == {"offset": 512, "type": "string"}


def test_no_merge_with_list_values():
    """no_merge works with list values too."""
    parent = {"detect": [{"offset": 0}]}
    child = {"detect": [{"offset": 512}]}
    result = merge_meta(parent, child, no_merge={"detect"})
    # Child list should replace parent list entirely
    assert result["detect"] == [{"offset": 512}]


def test_normal_keys_still_deep_merge():
    """Keys not in no_merge still deep merge as usual."""
    parent = {"config": {"a": 1, "b": 2}}
    child = {"config": {"b": 3, "c": 4}}
    result = merge_meta(parent, child, no_merge={"detect"})
    assert result["config"] == {"a": 1, "b": 3, "c": 4}
