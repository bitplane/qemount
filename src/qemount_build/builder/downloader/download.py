#!/usr/bin/env python3
"""
Source downloader entrypoint.

Reads META env var, downloads from urls, writes to provides path.
"""

import json
import os
import shutil
import sys
import urllib.request
from pathlib import Path


def download_file(url: str, dest: Path) -> bool:
    """Download a file from URL to dest."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".tmp")

    try:
        print(f"  Trying: {url}")
        with urllib.request.urlopen(url, timeout=60) as response:
            with open(tmp, "wb") as f:
                shutil.copyfileobj(response, f)
        tmp.rename(dest)
        print(f"  OK: {dest}")
        return True
    except Exception as e:
        print(f"  Failed: {e}")
        tmp.unlink(missing_ok=True)
        return False


def main():
    meta_json = os.environ.get("META")
    if not meta_json:
        print("Error: META environment variable not set")
        return 1

    meta = json.loads(meta_json)

    urls = meta.get("urls", [])
    if not urls:
        print("Error: no urls in META")
        return 1

    provides = meta.get("provides", {})
    if not provides:
        print("Error: no provides in META")
        return 1

    # Get first provides key as output path
    output = next(iter(provides.keys()))
    dest = Path("/host/build") / output

    if dest.exists():
        print(f"Already exists: {dest}")
        return 0

    print(f"Downloading: {output}")
    for url in urls:
        if download_file(url, dest):
            return 0

    print(f"Error: all URLs failed for {output}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
