from importlib.metadata import version

import mountin


def test_version_matches_distribution():
    assert mountin.__version__ == version("mountin")
