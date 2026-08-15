#!/usr/bin/env python3
"""Merge BusyBox configuration files.

Reads base and override configs, merges them (override wins), writes output.
"""

import sys


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <base> <override> <output>")
        sys.exit(1)

    configs = {}

    with open(sys.argv[1]) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if "is not set" in line:
                key = line.split()[1]
                configs[key] = line
            elif line.startswith("CONFIG_") and "=" in line:
                key = line.split("=")[0]
                configs[key] = line if not line.endswith("=n") else f"# {key} is not set"

    with open(sys.argv[2]) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if "is not set" in line:
                key = line.split()[1]
                configs[key] = line
            elif line.startswith("CONFIG_") and "=" in line:
                key = line.split("=")[0]
                configs[key] = line if not line.endswith("=n") else f"# {key} is not set"

    with open(sys.argv[3], "w") as f:
        f.write("# Automatically generated config: do not edit\n")
        for line in configs.values():
            f.write(f"{line}\n")


if __name__ == "__main__":
    main()
