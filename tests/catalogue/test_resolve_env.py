"""Tests for catalogue.resolve_env."""

import pytest

from qemount_build.catalogue import resolve_env


@pytest.mark.parametrize("env,context,expected", [
    # simple value
    ({"A": "value"}, {}, {"A": "value"}),
    # from context
    ({"A": "${X}"}, {"X": "fromctx"}, {"X": "fromctx", "A": "fromctx"}),
    # definition order - B references A defined earlier
    ({"A": "first", "B": "${A}/second"}, {}, {"A": "first", "B": "first/second"}),
    # override context
    ({"X": "new"}, {"X": "old"}, {"X": "new"}),
])
def test_resolve_env(env, context, expected):
    assert resolve_env(env, context) == expected


def test_resolve_env_chain():
    """Simulate walking ancestor chain."""
    ctx = {"ROOT": "r"}
    ctx = resolve_env({"A": "${ROOT}/a"}, ctx)
    ctx = resolve_env({"B": "${A}/b"}, ctx)
    assert ctx == {"ROOT": "r", "A": "r/a", "B": "r/a/b"}
