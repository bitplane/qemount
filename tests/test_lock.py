import pytest

from qemount_build.lock import BuildDirectoryBusy, build_directory_lock


def test_build_directory_lock_rejects_a_second_owner(tmp_path):
    with build_directory_lock(tmp_path):
        with pytest.raises(BuildDirectoryBusy):
            with build_directory_lock(tmp_path, blocking=False):
                pass


def test_build_directory_lock_is_released(tmp_path):
    with build_directory_lock(tmp_path):
        pass

    with build_directory_lock(tmp_path, blocking=False):
        pass
