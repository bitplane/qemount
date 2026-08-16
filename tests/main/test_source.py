import subprocess
from pathlib import Path

from mountin.source import (
    SourceAuthority,
    distribution_entry,
    export_source_tree,
    project_files,
)


def initialize_repository(path):
    subprocess.run(["git", "init", "-q", path], check=True)
    subprocess.run(
        ["git", "config", "user.email", "test@example.com"], cwd=path, check=True
    )
    subprocess.run(
        ["git", "config", "user.name", "Test"], cwd=path, check=True
    )


def test_project_files_include_working_changes_and_exclude_ignored_files(tmp_path):
    initialize_repository(tmp_path)
    (tmp_path / ".gitignore").write_text("ignored\n")
    (tmp_path / "tracked").write_text("original")
    subprocess.run(["git", "add", ".gitignore", "tracked"], cwd=tmp_path, check=True)
    subprocess.run(["git", "commit", "-qm", "initial"], cwd=tmp_path, check=True)
    (tmp_path / "tracked").write_text("modified")
    (tmp_path / "untracked").write_text("new")
    (tmp_path / "ignored").write_text("ignored")

    assert project_files(tmp_path) == [
        Path(".gitignore"),
        Path("tracked"),
        Path("untracked"),
    ]


def test_source_tree_contains_working_tree_and_preserves_file_types(tmp_path):
    repository = tmp_path / "repository"
    repository.mkdir()
    initialize_repository(repository)
    (repository / ".gitignore").write_text("ignored\n")
    (repository / "file").write_text("original")
    subprocess.run(["git", "add", ".gitignore", "file"], cwd=repository, check=True)
    subprocess.run(["git", "commit", "-qm", "initial"], cwd=repository, check=True)
    (repository / "file").write_text("modified")
    (repository / "executable").write_text("#!/bin/sh\n")
    (repository / "executable").chmod(0o755)
    (repository / "link").symlink_to("file")
    (repository / "ignored").write_text("ignored")

    destination = tmp_path / "output" / "mountin"
    identity, changed = export_source_tree(
        SourceAuthority("checkout", repository), destination
    )

    assert changed
    assert (destination / "file").read_text() == "modified"
    assert (destination / "executable").stat().st_mode & 0o111
    assert (destination / "link").is_symlink()
    assert (destination / "link").readlink() == Path("file")
    assert not (destination / "ignored").exists()

    inode = destination.stat().st_ino
    repeated_identity, changed = export_source_tree(
        SourceAuthority("checkout", repository), destination, identity
    )
    assert repeated_identity == identity
    assert not changed
    assert destination.stat().st_ino == inode


def test_distribution_entries_use_canonical_package_layout(tmp_path):
    source = tmp_path / "main.py"
    source.write_text("pass\n")

    entry = distribution_entry(source, Path("mountin/main.py"))

    assert entry is not None
    assert entry.source == source
    assert entry.relative == Path("src/mountin/main.py")
    assert distribution_entry(source, Path("mountin-0.1.dist-info/RECORD")) is None
