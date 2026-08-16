#!/usr/bin/env python3

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


source = Path(sys.argv[1])
destination = Path(sys.argv[2])
manifest = Path(sys.argv[3])
library_directories = ("lib", "lib/priv", "usr/lib", "usr/lib/priv")


def copy(relative: str) -> bool:
    relative_path = Path(relative.lstrip("/"))
    source_path = source / relative_path
    destination_path = destination / relative_path

    if destination_path.exists() or destination_path.is_symlink():
        return False
    if not source_path.exists() and not source_path.is_symlink():
        raise FileNotFoundError(relative)

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    if source_path.is_symlink():
        target = os.readlink(source_path)
        destination_path.symlink_to(target)
        resolved = (source_path.parent / target).resolve()
        copy(str(resolved.relative_to(source.resolve())))
    elif source_path.is_dir():
        destination_path.mkdir()
        shutil.copystat(source_path, destination_path, follow_symlinks=False)
    else:
        shutil.copy2(source_path, destination_path)
    return True


def elf_dependencies(path: Path) -> tuple[list[str], str | None]:
    if path.relative_to(destination) == Path("boot/kernel/kernel"):
        return [], None

    result = subprocess.run(
        ["readelf", "-d", "-l", path],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return [], None

    libraries = re.findall(r"Shared library: \[([^]]+)]", result.stdout)
    match = re.search(r"Requesting program interpreter: ([^]]+)]", result.stdout)
    return libraries, match.group(1) if match else None


def find_library(name: str) -> str:
    for directory in library_directories:
        candidate = source / directory / name
        if candidate.exists() or candidate.is_symlink():
            return str(candidate.relative_to(source))
    raise FileNotFoundError(f"shared library {name}")


for line in manifest.read_text().splitlines():
    line = line.strip()
    if line and not line.startswith("#"):
        copy(line)

changed = True
while changed:
    changed = False
    for path in tuple(destination.rglob("*")):
        if not path.is_file() or path.is_symlink():
            continue
        libraries, interpreter = elf_dependencies(path)
        if interpreter and interpreter != "/red/herring":
            changed |= copy(interpreter)
        for library in libraries:
            changed |= copy(find_library(library))
