"""Select and export the source tree used by a Mountin build."""

import hashlib
import os
import shutil
import stat
import subprocess
from dataclasses import dataclass
from importlib.metadata import files as distribution_files
from pathlib import Path

SOURCE_EPOCH = 315532800


@dataclass(frozen=True)
class SourceEntry:
    """One source file and its path in the canonical project tree."""

    source: Path
    relative: Path


@dataclass(frozen=True)
class SourceAuthority:
    """The checkout or installed distribution supplying build inputs."""

    kind: str
    root: Path

    @property
    def catalogue_root(self) -> Path:
        if self.kind == "checkout":
            return self.root / "src" / "mountin"
        return self.root

    @property
    def repository(self) -> Path | None:
        return self.root if self.kind == "checkout" else None


def _checkout_root(start: Path) -> Path | None:
    try:
        root = Path(
            subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                cwd=start,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    return root if (root / "src" / "mountin").is_dir() else None


def resolve_source_authority() -> SourceAuthority:
    """Select the checkout containing this code, or the installed package."""
    package = Path(__file__).resolve().parent
    checkout = _checkout_root(package) or _checkout_root(Path.cwd())
    if checkout is not None:
        return SourceAuthority("checkout", checkout)
    return SourceAuthority("distribution", package)


def project_files(repository: Path) -> list[Path]:
    """Return tracked and non-ignored untracked files in a checkout."""
    output = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=repository,
        check=True,
        capture_output=True,
    ).stdout
    return sorted(Path(os.fsdecode(name)) for name in output.split(b"\0") if name)


def distribution_entry(source: Path, relative: Path) -> SourceEntry | None:
    """Map one installed distribution record into the canonical tree."""
    if not relative.parts or relative.parts[0] != "mountin":
        return None
    if not source.is_file() and not source.is_symlink():
        return None
    return SourceEntry(source, Path("src") / relative)


def source_entries(authority: SourceAuthority) -> list[SourceEntry]:
    """Return files from an authority in canonical project-tree locations."""
    if authority.kind == "checkout":
        return [
            SourceEntry(authority.root / relative, relative)
            for relative in project_files(authority.root)
            if (authority.root / relative).exists()
            or (authority.root / relative).is_symlink()
        ]

    records = distribution_files("mountin") or []
    entries = []
    for record in records:
        relative = Path(str(record))
        source = Path(record.locate())
        entry = distribution_entry(source, relative)
        if entry is not None:
            entries.append(entry)
    return sorted(entries, key=lambda entry: str(entry.relative))


def _digest_field(digest, value: bytes) -> None:
    digest.update(len(value).to_bytes(8, "little"))
    digest.update(value)


def _copy_entry(entry: SourceEntry, destination: Path, digest) -> None:
    relative = entry.relative
    source = entry.source
    target = destination / relative
    mode = stat.S_IMODE(source.lstat().st_mode)
    _digest_field(digest, os.fsencode(relative))
    digest.update(mode.to_bytes(4, "little"))

    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_symlink():
        link = os.readlink(source)
        digest.update(b"L")
        _digest_field(digest, os.fsencode(link))
        target.symlink_to(link)
        return

    digest.update(b"F")
    content_digest = hashlib.sha256()
    with source.open("rb") as input_file, target.open("wb") as output_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            content_digest.update(chunk)
            output_file.write(chunk)
    digest.update(content_digest.digest())
    target.chmod(mode)
    os.utime(target, (SOURCE_EPOCH, SOURCE_EPOCH))


def _remove_tree(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


def export_source_tree(
    authority: SourceAuthority,
    destination: Path,
    previous_identity: str | None = None,
) -> tuple[str, bool]:
    """Atomically export an authority, retaining an identical existing tree."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(f"{destination.name}.tmp.{os.getpid()}")
    backup = destination.with_name(f"{destination.name}.mountin-previous")
    _remove_tree(temporary)

    if backup.exists() and not destination.exists():
        backup.rename(destination)
    elif backup.exists():
        _remove_tree(backup)

    digest = hashlib.sha256()
    temporary.mkdir()
    try:
        for entry in source_entries(authority):
            _copy_entry(entry, temporary, digest)
        identity = digest.hexdigest()

        if previous_identity == identity and destination.is_dir():
            _remove_tree(temporary)
            return identity, False

        if destination.exists() or destination.is_symlink():
            destination.rename(backup)
        try:
            temporary.rename(destination)
        except BaseException:
            if backup.exists() and not destination.exists():
                backup.rename(destination)
            raise
        _remove_tree(backup)
        return identity, True
    finally:
        _remove_tree(temporary)
