#!/usr/bin/env python3
"""Generate an AmigaDOS script which reproduces a test-data template."""

from __future__ import annotations

import argparse
import os
from pathlib import Path, PurePosixPath
import stat


def amiga_path(prefix: str, relative: PurePosixPath) -> str:
    value = f"{prefix}{relative.as_posix()}"
    if any(character in value for character in ('"', "\r", "\n")):
        raise ValueError(f"unsupported character in AmigaDOS path: {value!r}")
    return f'"{value}"'


def collect(root: Path) -> tuple[list[Path], list[Path], list[Path]]:
    directories = [root]
    files: list[Path] = []
    links: list[Path] = []

    for current, names, filenames in os.walk(root, followlinks=False):
        current_path = Path(current)
        for name in names + filenames:
            path = current_path / name
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                links.append(path)
            elif stat.S_ISDIR(mode):
                directories.append(path)
            elif stat.S_ISREG(mode):
                files.append(path)
            else:
                raise ValueError(f"unsupported template entry: {path}")

    key = lambda path: path.relative_to(root.parent).parts
    return sorted(directories, key=key), sorted(files, key=key), sorted(
        links, key=key
    )


def generate(root: Path) -> str:
    directories, files, links = collect(root)
    lines = ["FailAt 5"]

    for path in directories:
        relative = PurePosixPath(path.relative_to(root.parent).as_posix())
        lines.append(f"C:MakeDir {amiga_path('DH0:', relative)}")

    for path in files:
        relative = PurePosixPath(path.relative_to(root.parent).as_posix())
        source = amiga_path("SYS:TestData/", relative)
        destination = amiga_path("DH0:", relative)
        lines.append(f"C:Copy {source} {destination} CLONE ERRWARN")

    for path in links:
        relative = PurePosixPath(path.relative_to(root.parent).as_posix())
        target = PurePosixPath(os.readlink(path))
        if target.is_absolute():
            raise ValueError(f"absolute template link is not portable: {path}")

        resolved = PurePosixPath(
            os.path.normpath((relative.parent / target).as_posix())
        )
        if not resolved.parts or resolved.parts[0] != root.name:
            raise ValueError(f"template link escapes its root: {path}")

        link_name = amiga_path("DH0:", relative)
        link_target = amiga_path("DH0:", resolved)
        lines.append(f"C:MakeLink {link_name} {link_target}")

    lines.append('Echo "Test-data population complete" >SER:')
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("template", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.write_text(generate(args.template), encoding="ascii")


if __name__ == "__main__":
    main()
