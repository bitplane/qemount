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

from .catalogue import load, build_provides_index, build_graph
from .runner import run_build
from .cache import load_cache, save_cache, hash_file
from . import log as logsetup

log = logging.getLogger(__name__)


def get_default_arch():
    """Get default architecture from platform."""
    machine = platform.machine()
    return {"x86_64": "x86_64", "aarch64": "aarch64", "arm64": "aarch64"}.get(
        machine, machine
    )


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
    index = build_provides_index(catalogue, context)
    for output in sorted(index.keys()):
        if args.verbose:
            print(f"{output}\t{index[output]}")
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
    hash_file(catalogue_file, cache)
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


def main():
    parser = argparse.ArgumentParser(
        prog="qemount_build",
        description="Catalogue inspection tool for qemount build system",
    )
    parser.add_argument(
        "--arch",
        default=get_default_arch(),
        help="Target architecture (default: %(default)s)",
    )
    parser.add_argument(
        "--host-arch",
        default=get_default_arch(),
        help="Host architecture (default: %(default)s)",
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

    args = parser.parse_args()

    # Configure logging
    logsetup.setup(args.log_level)

    # Load catalogue
    pkg_dir = Path(__file__).parent
    catalogue = load(pkg_dir)

    # Build context
    context = {
        "ARCH": args.arch,
        "HOST_ARCH": args.host_arch,
        "JOBS": str(get_jobs()),
    }

    # Run command
    result = args.func(args, catalogue, context)
    return result or 0


if __name__ == "__main__":
    exit(main())
