#!/usr/bin/env python
# merge_config.py - Merge BusyBox configuration files efficiently
# Python 2.6 compatible (no f-strings)

import sys

def main():
    if len(sys.argv) != 4:
        print("Usage: python merge_config.py <base_config> <override_config> <output_config>")
        sys.exit(1)

    configs = {}
    count = 0

    # Read all input lines from both files as a stream
    for line in open(sys.argv[1]).readlines() + open(sys.argv[2]).readlines():
        line = line.strip()
        if not line or (line.startswith('#') and "is not set" not in line):
            continue

        if "is not set" in line:
            key = line.split()[1]
            configs[key] = line
        elif "=" in line and line.startswith("CONFIG_"):
            key = line.split("=")[0]
            if line.endswith("=n"):
                configs[key] = "# " + key + " is not set"
            else:
                configs[key] = line
        else:
            configs[count] = line
        count += 1  # Count every line we process

    # Write merged config
    with open(sys.argv[3], 'w') as f:
        f.write("# Automatically generated config: do not edit\n")
        for line in configs.values():
            f.write(line + "\n")

if __name__ == "__main__":
    main()
