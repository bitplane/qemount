#!/usr/bin/env python3
"""
Source downloader entrypoint.

Reads META env var, downloads from urls, writes to provides path.

Supports:
- http/https URLs: direct download
- git+https://...#tag: clone at tag, export as tarball
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
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger(__name__)


def download_file(url: str, dest: Path) -> bool:
    """Download a file from URL to dest."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".tmp")

    try:
        log.info("Trying: %s", url)
        with urllib.request.urlopen(url, timeout=60) as response:
            with open(tmp, "wb") as f:
                shutil.copyfileobj(response, f)
        tmp.rename(dest)
        log.info("OK: %s", dest)
        return True
    except Exception as e:
        log.warning("Failed: %s", e)
        tmp.unlink(missing_ok=True)
        return False


def clone_repo(url: str, dest: Path) -> bool:
    """Clone a git repo and export as tarball.

    URL format: git+https://github.com/user/repo.git#tag
    """
    dest.parent.mkdir(parents=True, exist_ok=True)

    if "#" not in url:
        log.warning("Git URL missing #tag: %s", url)
        return False

    repo_url, ref = url[4:].split("#", 1)  # Strip "git+" prefix
    repo_name = repo_url.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git")
    export_name = f"{repo_name}-{ref}"  # e.g. haiku-r1beta5

    log.info("Cloning: %s @ %s", repo_url, ref)

    with tempfile.TemporaryDirectory() as tmpdir:
        clone_dir = Path(tmpdir) / export_name

        result = subprocess.run(
            ["git", "clone", "--depth", "1", "--branch", ref, repo_url, str(clone_dir)],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            log.warning("Clone failed: %s", result.stderr.strip())
            return False

        # Create tarball (keep .git - some build systems need it)
        log.info("Creating tarball: %s", dest)
        with tarfile.open(dest, "w:gz") as tar:
            tar.add(clone_dir, arcname=export_name)

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

    if dest.exists():
        log.info("Already exists: %s", dest)
        return 0

    log.info("Downloading: %s", output)
    for url in urls:
        if fetch(url, dest):
            return 0

    log.error("All URLs failed for %s", output)
    return 1


if __name__ == "__main__":
    sys.exit(main())
