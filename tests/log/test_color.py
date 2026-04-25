"""Tests for log color suppression on non-tty streams."""

import io
import logging

from qemount_build.log import ColorFormatter, RESET


def make_record(level=logging.INFO, msg='hello'):
    return logging.LogRecord('test', level, __file__, 0, msg, (), None)


def test_colors_emitted_when_enabled():
    formatter = ColorFormatter('%(message)s', use_color=True)
    out = formatter.format(make_record())
    assert '\033[' in out
    assert out.endswith(RESET)


def test_colors_suppressed_when_disabled():
    formatter = ColorFormatter('%(message)s', use_color=False)
    out = formatter.format(make_record())
    assert '\033[' not in out
    assert out == 'hello'


def test_setup_disables_color_for_non_tty(monkeypatch):
    from qemount_build import log as logmod

    buf = io.StringIO()
    monkeypatch.setattr(logmod.sys, 'stderr', buf)

    root = logging.getLogger()
    original_handlers = root.handlers[:]
    original_level = root.level
    try:
        root.handlers = []
        logmod.setup('info')
        logging.getLogger('color-test').info('plain message')
    finally:
        root.handlers = original_handlers
        root.setLevel(original_level)

    output = buf.getvalue()
    assert 'plain message' in output
    assert '\033[' not in output
