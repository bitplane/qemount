"""
Dump catalogue as JSON for inspection.

Usage:
    python -m qemount_build
    python -m qemount_build | jq '.paths["format/fs/ext4"]'
"""

import json
from pathlib import Path

from .catalogue import load


def main():
    # Load from package directory
    pkg_dir = Path(__file__).parent
    catalogue = load(pkg_dir)

    # Dump as JSON
    print(json.dumps(catalogue, indent=2))


if __name__ == "__main__":
    main()
