"""Tests for catalogue.resolve_vars."""

import pytest

from qemount_build.catalogue import resolve_vars


@pytest.mark.parametrize("value,context,expected", [
    ("hello world", {}, "hello world"),
    ("${FOO}", {"FOO": "bar"}, "bar"),
    ("hello ${NAME}!", {"NAME": "world"}, "hello world!"),
    ("${A} + ${B}", {"A": "1", "B": "2"}, "1 + 2"),
    ("${MISSING}", {}, "${MISSING}"),
    ("${A}/${B}", {"A": "foo"}, "foo/${B}"),
    ("count: ${N}", {"N": 42}, "count: 42"),
    ("path/${ARCH}/bin", {"ARCH": "x86_64"}, "path/x86_64/bin"),
])
def test_resolve_vars(value, context, expected):
    assert resolve_vars(value, context) == expected
