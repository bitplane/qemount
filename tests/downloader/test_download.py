import subprocess
import tarfile

from qemount_build.builder.downloader.download import clone_repo, temporary_output


def test_temporary_outputs_are_unique(tmp_path):
    destination = tmp_path / "source.tar.gz"

    with temporary_output(destination) as first:
        with temporary_output(destination) as second:
            assert first != second
            assert first.parent == destination.parent
            assert second.parent == destination.parent

    assert list(tmp_path.iterdir()) == []


def test_clone_repo_publishes_complete_archive(tmp_path):
    repository = tmp_path / "repository"
    destination = tmp_path / "output" / "source.tar.gz"
    repository.mkdir()
    subprocess.run(["git", "init", "-b", "main"], cwd=repository, check=True)
    (repository / "content.txt").write_text("complete\n")
    subprocess.run(["git", "add", "content.txt"], cwd=repository, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=qemount tests",
            "-c",
            "user.email=tests@qemount.invalid",
            "commit",
            "-m",
            "fixture",
        ],
        cwd=repository,
        check=True,
    )

    assert clone_repo(f"git+file://{repository}#main", destination)

    with tarfile.open(destination, "r:gz") as archive:
        assert "repository-main/content.txt" in archive.getnames()
    assert list(destination.parent.glob("*.tmp")) == []
