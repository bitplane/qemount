"""Tests for catalogue.resolve_value."""

import pytest

from qemount_build.catalogue import resolve_value


@pytest.mark.parametrize("value,context,expected", [
    # strings
    ("${X}", {"X": "y"}, "y"),
    ("plain", {}, "plain"),
    # lists
    (["${A}", "${B}"], {"A": "1", "B": "2"}, ["1", "2"]),
    # dict values
    ({"key": "${V}"}, {"V": "val"}, {"key": "val"}),
    # dict keys
    ({"${K}": "value"}, {"K": "mykey"}, {"mykey": "value"}),
    # nested
    ({"outer": {"inner": ["${X}"]}}, {"X": "deep"}, {"outer": {"inner": ["deep"]}}),
    # passthrough
    (42, {}, 42),
    (None, {}, None),
    (True, {}, True),
])
def test_resolve_value(value, context, expected):
    assert resolve_value(value, context) == expected
