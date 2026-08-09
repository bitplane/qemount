"""Cross-process locking for a qemount build directory."""

import fcntl
from contextlib import contextmanager
from pathlib import Path


class BuildDirectoryBusy(RuntimeError):
    """Raised when another process owns the build directory."""


@contextmanager
def build_directory_lock(build_dir: Path, blocking: bool = True):
    """Exclusively lock a build directory for a build-state operation."""
    lock_path = build_dir / "cache" / ".qemount" / "build.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a+") as lock_file:
        operation = fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB)
        try:
            fcntl.flock(lock_file, operation)
        except BlockingIOError as error:
            raise BuildDirectoryBusy(
                f"build directory is in use: {build_dir}"
            ) from error
        try:
            yield
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)
