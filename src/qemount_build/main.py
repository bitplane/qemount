"""
Catalogue inspection tool.

Usage:
    python -m qemount_build dump
    python -m qemount_build outputs
    python -m qemount_build deps build/data/fs/basic.ext2
"""

import argparse
import json
import logging
import platform
import sys
from pathlib import Path

from .catalogue import load, build_provides_index, build_graph
from .runner import run_build

log = logging.getLogger(__name__)


def get_default_arch():
    """Get default architecture from platform."""
    machine = platform.machine()
    return {"x86_64": "x86_64", "aarch64": "aarch64", "arm64": "aarch64"}.get(
        machine, machine
    )


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
    """Show dependency graph for a target."""
    try:
        graph = build_graph(args.target, catalogue, context)
    except KeyError as e:
        log.error("%s", e)
        return 1

    if args.order:
        for path in graph["order"]:
            print(path)
    else:
        print(f"Target: {args.target}")
        print(f"Provider: {graph['target']}")
        print(f"\nBuild order ({len(graph['order'])} steps):")
        for i, path in enumerate(graph["order"], 1):
            print(f"  {i}. {path}")

    return 0


def cmd_build(args, catalogue, context):
    """Build a target and its dependencies."""
    pkg_dir = Path(__file__).parent
    build_dir = Path("build").absolute()
    build_dir.mkdir(exist_ok=True)

    for target in args.targets:
        success = run_build(
            target,
            catalogue,
            context,
            build_dir,
            pkg_dir,
            force=args.force,
        )
        if not success:
            return 1
    return 0


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
        "-v", "--verbose",
        action="store_true",
        help="Verbose output (debug logging)",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Quiet output (errors only)",
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
    deps_parser = subparsers.add_parser("deps", help="Show dependencies for a target")
    deps_parser.add_argument("target", help="Target output to build")
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
    if args.quiet:
        level = logging.ERROR
    elif args.verbose:
        level = logging.DEBUG
    else:
        level = logging.INFO

    logging.basicConfig(
        level=level,
        format="%(levelname)s: %(message)s",
        stream=sys.stderr,
    )

    # Load catalogue
    pkg_dir = Path(__file__).parent
    catalogue = load(pkg_dir)

    # Build context
    context = {"ARCH": args.arch, "HOST_ARCH": args.host_arch}

    # Run command
    result = args.func(args, catalogue, context)
    return result or 0


if __name__ == "__main__":
    exit(main())
