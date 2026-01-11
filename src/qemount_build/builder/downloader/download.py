#!/usr/bin/env python3
"""
Source downloader entrypoint.

Reads META env var, downloads from urls, writes to provides path.
"""

import json
import logging
import os
import shutil
import sys
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
        if download_file(url, dest):
            return 0

    log.error("All URLs failed for %s", output)
    return 1


if __name__ == "__main__":
    sys.exit(main())
