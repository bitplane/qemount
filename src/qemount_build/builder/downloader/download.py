#!/usr/bin/env python3
"""
Source downloader entrypoint.

Reads META env var, downloads from urls, writes to provides path.

Supports:
- http/https URLs: direct download
- git+https://...#ref: clone at a branch, tag, or commit with submodules,
  then export as a tarball
"""

import json
import logging
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from contextlib import contextmanager
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger(__name__)


@contextmanager
def temporary_output(dest: Path):
    """Create a unique temporary output beside its destination."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(
        dir=dest.parent,
        prefix=f".{dest.name}.",
        suffix=".tmp",
    )
    os.close(fd)
    tmp = Path(name)
    try:
        yield tmp
    finally:
        tmp.unlink(missing_ok=True)


def download_file(url: str, dest: Path) -> bool:
    """Download a file from URL to dest."""
    try:
        with temporary_output(dest) as tmp:
            log.info("Trying: %s", url)
            with urllib.request.urlopen(url, timeout=60) as response:
                length = response.headers.get("Content-Length")
                expected = int(length) if length is not None else None
                with open(tmp, "wb") as f:
                    shutil.copyfileobj(response, f)

            # A connection closed early reads as a clean EOF here:
            # urllib/shutil raise nothing and we get a short file.
            got = tmp.stat().st_size
            if expected is not None and got != expected:
                raise OSError(f"incomplete download: got {got} of {expected} bytes")

            tmp.replace(dest)
        log.info("OK: %s (%d bytes)", dest, got)
        return True
    except Exception as e:
        log.warning("Failed: %s", e)
        return False


def clone_repo(url: str, dest: Path) -> bool:
    """Clone a git repo and export as tarball.

    URL format: git+https://github.com/user/repo.git#ref
    """
    dest.parent.mkdir(parents=True, exist_ok=True)

    if "#" not in url:
        log.warning("Git URL missing #ref: %s", url)
        return False

    repo_url, ref = url[4:].split("#", 1)  # Strip "git+" prefix
    repo_name = repo_url.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git")
    export_name = f"{repo_name}-{ref}"  # e.g. haiku-r1beta5

    log.info("Cloning: %s @ %s", repo_url, ref)

    with tempfile.TemporaryDirectory() as tmpdir:
        clone_dir = Path(tmpdir) / export_name

        commands = [
            ["git", "init", str(clone_dir)],
            ["git", "-C", str(clone_dir), "remote", "add", "origin", repo_url],
            ["git", "-C", str(clone_dir), "fetch", "--depth", "1", "origin", ref],
            ["git", "-C", str(clone_dir), "checkout", "--detach", "FETCH_HEAD"],
            [
                "git",
                "-C",
                str(clone_dir),
                "submodule",
                "update",
                "--init",
                "--recursive",
                "--depth",
                "1",
            ],
        ]
        for command in commands:
            result = subprocess.run(command, capture_output=True, text=True)
            if result.returncode != 0:
                log.warning("Git command failed: %s", result.stderr.strip())
                return False

        log.info("Creating tarball: %s", dest)
        with temporary_output(dest) as tmp:
            with tarfile.open(tmp, "w:gz") as tar:
                tar.add(clone_dir, arcname=export_name)
            tmp.replace(dest)

    log.info("OK: %s", dest)
    return True


def fetch(url: str, dest: Path) -> bool:
    """Fetch from URL - dispatches to appropriate handler."""
    if url.startswith("git+"):
        return clone_repo(url, dest)
    return download_file(url, dest)


def main():
    meta_json = os.environ.get("META")
    if not meta_json:
        log.error("META environment variable not set")
        return 1

    meta = json.loads(meta_json)

    urls = meta.get("urls", [])
    if not urls:
        log.error("No urls in META")
        return 1

    provides = meta.get("provides", {})
    if not provides:
        log.error("No provides in META")
        return 1

    # Get first provides key as output path
    output = next(iter(provides.keys()))
    dest = Path("/host/build") / output

    log.info("Downloading: %s", output)
    for url in urls:
        if fetch(url, dest):
            return 0

    log.error("All URLs failed for %s", output)
    return 1


if __name__ == "__main__":
    sys.exit(main())
