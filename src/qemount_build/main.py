"""
Catalogue inspection tool.

Usage:
    qemount-build dump
    qemount-build outputs
    qemount-build deps "data/fs/*.ext*"
    qemount-build build "data/pt/*"
"""

import argparse
import fnmatch
import json
import logging
import os
import platform
import sys
from pathlib import Path

from .catalogue import build_graph, build_output_index, build_provides_index, load
from .runner import run_build
from .inventory import create_inventory, write_inventory
from .cache import load_cache, save_cache, hash_file
from . import log as logsetup

log = logging.getLogger(__name__)


def get_default_arch():
    """Get the canonical architecture of the build machine."""
    machine = platform.machine()
    return {"x86_64": "x86_64", "aarch64": "aarch64", "arm64": "aarch64"}.get(
        machine, machine
    )


def get_default_build_platform():
    """Get the canonical platform of the build machine."""
    system = {"linux": "linux", "darwin": "darwin", "win32": "windows"}.get(
        sys.platform, sys.platform
    )
    return f"{get_default_arch()}-{system}"


def build_context(build_platform: str) -> dict:
    """Create the immutable context shared by all provider variants."""
    parts = build_platform.split("-")
    if len(parts) != 2:
        raise ValueError(f"Invalid build platform: {build_platform}")
    return {
        "BUILD_PLATFORM": build_platform,
        "BUILD_ARCH": parts[0],
        "BUILD_OS": parts[1],
        "JOBS": str(get_jobs()),
    }


def get_jobs():
    """Calculate parallel jobs based on RAM and CPU cores.

    Formula: min(RAM_GB / 2, cores, 16)
    Capped at 16 to avoid vfork resource exhaustion on large machines.
    """
    mem_gb = os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") // (1024**3)
    cores = os.cpu_count() or 1
    return max(1, min(mem_gb // 2, cores, 16))


def cmd_dump(args, catalogue, context):
    """Dump full catalogue as JSON."""
    print(json.dumps(catalogue, indent=2))


def cmd_outputs(args, catalogue, context):
    """List all outputs (provides)."""
    outputs = build_output_index(catalogue, context, Path("build").absolute())
    selected_platforms = set(getattr(args, "output_platform", []) or [])
    all_platforms = getattr(args, "all_platforms", False)
    include_unavailable = getattr(args, "include_unavailable", False)
    outputs = {
        output: record
        for output, record in outputs.items()
        if (
            all_platforms
            or record["output_platform"] is None
            or record["output_platform"] in selected_platforms
            or (not selected_platforms and record["native"])
        )
        and (include_unavailable or record["buildable"])
    }
    for output, record in sorted(outputs.items()):
        if args.verbose:
            line = f"{output}\t{record['provider']}"
            if record["output_platform"]:
                line += f"\t{record['output_platform']}"
            if not record["buildable"]:
                line += f"\tunavailable: {record['reason']}"
            print(line)
        else:
            print(output)


def cmd_deps(args, catalogue, context):
    """Show dependency graph for targets."""
    build_dir = Path("build").absolute()
    targets = expand_targets(args.targets, catalogue, context)
    if not targets:
        log.error("No targets match")
        return 1

    try:
        graph = build_graph(targets, catalogue, context, build_dir)
    except KeyError as e:
        log.error("%s", e)
        return 1

    if args.order:
        for path in graph["order"]:
            print(path)
    else:
        print(f"Targets: {', '.join(targets)}")
        print(f"\nBuild order ({len(graph['order'])} steps):")
        for i, path in enumerate(graph["order"], 1):
            outputs = sorted(graph["needed"].get(path, []))
            print(f"  {i}. {path}")
            for output in outputs:
                print(f"       → {output}")

    return 0


def normalize_target(target: str) -> str:
    """Normalize a target path - strips 'build/' prefix for autocomplete convenience."""
    if target.startswith("build/"):
        return target[6:]
    return target


def expand_targets(patterns: list[str], catalogue: dict, context: dict) -> list[str]:
    """Expand target patterns to concrete targets.

    - Normalizes each target (strips 'build/' prefix)
    - Expands globs against available outputs
    """
    outputs = set(build_provides_index(catalogue, context).keys())
    targets = []

    for pattern in patterns:
        pattern = normalize_target(pattern)

        # Check for glob characters
        if any(c in pattern for c in "*?["):
            matches = [o for o in outputs if fnmatch.fnmatch(o, pattern)]
            if not matches:
                log.warning("No outputs match pattern: %s", pattern)
            targets.extend(sorted(matches))
        else:
            targets.append(pattern)

    return targets


def cmd_build(args, catalogue, context):
    """Build targets and their dependencies."""
    pkg_dir = Path(__file__).parent
    build_dir = Path("build").absolute()
    build_dir.mkdir(exist_ok=True)

    # Expand patterns and strip build/ prefix
    targets = expand_targets(args.targets, catalogue, context)
    if not targets:
        log.error("No targets to build")
        return 1

    # Dump catalogue as implicit dependency for all builds
    catalogue_file = build_dir / "catalogue.json"
    catalogue_file.write_text(json.dumps(catalogue, indent=2))
    log.debug("Wrote catalogue to %s", catalogue_file)

    # Update cache with new catalogue hash so dependents see the change
    cache = load_cache(build_dir)
    hash_file(catalogue_file, cache, "build:catalogue.json")
    save_cache(build_dir, cache)

    success = run_build(
        targets,
        catalogue,
        context,
        build_dir,
        pkg_dir,
        force=args.force,
    )
    return 0 if success else 1


def cmd_inventory(args, catalogue, context):
    """Record the concrete catalogue artefacts currently present."""
    build_dir = Path("build").absolute()
    inventory, unknown = create_inventory(catalogue, context, build_dir)
    destination = Path(args.output)
    write_inventory(inventory, destination)
    for path in unknown:
        log.warning("Unknown build artefact: %s", path)
    log.info("Wrote %d artefacts to %s", len(inventory["artefacts"]), destination)


def main():
    parser = argparse.ArgumentParser(
        prog="qemount_build",
        description="Catalogue inspection tool for qemount build system",
    )
    parser.add_argument(
        "--build-platform",
        default=os.environ.get("BUILD_PLATFORM", get_default_build_platform()),
        help="Build machine platform (default: %(default)s)",
    )
    parser.add_argument(
        "--log-level",
        choices=list(logsetup.LEVELS.keys()),
        default="info",
        help="Log level (default: info)",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # dump
    dump_parser = subparsers.add_parser("dump", help="Dump full catalogue as JSON")
    dump_parser.set_defaults(func=cmd_dump)

    # outputs
    outputs_parser = subparsers.add_parser("outputs", help="List all outputs")
    outputs_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show provider path"
    )
    outputs_parser.add_argument(
        "--output-platform",
        action="append",
        default=[],
        help="Select an output platform (repeatable)",
    )
    outputs_parser.add_argument(
        "--all-platforms",
        action="store_true",
        help="Select every output platform buildable here",
    )
    outputs_parser.add_argument(
        "--include-unavailable",
        action="store_true",
        help="Include selected outputs unavailable on this build platform",
    )
    outputs_parser.set_defaults(func=cmd_outputs)

    # deps
    deps_parser = subparsers.add_parser("deps", help="Show dependencies for targets")
    deps_parser.add_argument("targets", nargs="+", help="Target outputs (supports globs)")
    deps_parser.add_argument(
        "--order", action="store_true", help="Print only build order, one per line"
    )
    deps_parser.set_defaults(func=cmd_deps)

    # build
    build_parser = subparsers.add_parser("build", help="Build a target")
    build_parser.add_argument("targets", nargs="+", help="Target outputs to build")
    build_parser.add_argument(
        "-f", "--force", action="store_true", help="Force rebuild even if exists"
    )
    build_parser.set_defaults(func=cmd_build)

    inventory_parser = subparsers.add_parser(
        "inventory", help="Inventory catalogue artefacts present in build/"
    )
    inventory_parser.add_argument(
        "--output", default="build/inventory.json", help="Inventory destination"
    )
    inventory_parser.set_defaults(func=cmd_inventory)

    args = parser.parse_args()

    # Configure logging
    logsetup.setup(args.log_level)

    # Load catalogue
    pkg_dir = Path(__file__).parent
    catalogue = load(pkg_dir)

    # Build context
    context = build_context(args.build_platform)

    # Run command
    result = args.func(args, catalogue, context)
    return result or 0


if __name__ == "__main__":
    exit(main())
