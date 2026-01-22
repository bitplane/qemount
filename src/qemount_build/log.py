"""
Logging setup for qemount build system.

Adds TRACE level (below DEBUG) for detailed timing and function tracing.
"""

import logging
import sys
import time
from functools import wraps

# Add TRACE level
TRACE = 5
logging.addLevelName(TRACE, "TRACE")


def trace(self, message, *args, **kwargs):
    if self.isEnabledFor(TRACE):
        self._log(TRACE, message, args, **kwargs)


logging.Logger.trace = trace


LEVELS = {
    "trace": TRACE,
    "debug": logging.DEBUG,
    "info": logging.INFO,
    "warning": logging.WARNING,
    "error": logging.ERROR,
}

# ANSI color codes
COLORS = {
    TRACE: "\033[38;5;245m",      # light grey
    logging.DEBUG: "\033[38;5;240m",    # dark grey
    logging.INFO: "\033[32m",     # green
    logging.WARNING: "\033[33m",  # yellow
    logging.ERROR: "\033[31m",    # red
}
RESET = "\033[0m"


class ColorFormatter(logging.Formatter):
    """Formatter that adds colors based on log level."""

    def format(self, record):
        color = COLORS.get(record.levelno, "")
        message = super().format(record)
        return f"{color}{message}{RESET}"


def setup(level_name: str = "info"):
    """Configure logging with the given level."""
    level = LEVELS.get(level_name.lower(), logging.INFO)

    handler = logging.StreamHandler(sys.stderr)
    handler.setFormatter(ColorFormatter("%(asctime)s %(levelname)s: %(message)s", "%Y-%m-%d %H:%M:%S"))

    root = logging.getLogger()
    root.setLevel(level)
    root.addHandler(handler)


def timed(func):
    """Decorator to log function execution time at TRACE level."""
    logger = logging.getLogger(func.__module__)

    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        try:
            return func(*args, **kwargs)
        finally:
            elapsed = time.perf_counter() - start
            logger.trace("%s took %.3fs", func.__name__, elapsed)

    return wrapper
