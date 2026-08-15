import importlib.util
import struct
import sys
from pathlib import Path

import pytest


SCRIPT = (
    Path(__file__).parents[2]
    / "src/mountin_build/builder/disk/research-unix/mkresearchunix.py"
)
SPEC = importlib.util.spec_from_file_location("mkresearchunix", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
mkresearchunix = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mkresearchunix
SPEC.loader.exec_module(mkresearchunix)


def source_tree(tmp_path):
    source = tmp_path / "source"
    nested = source / "basic" / "nested_dir"
    nested.mkdir(parents=True)
    (source / "basic" / "hello.txt").write_bytes(b"hello\n")
    (nested / "file_in_dir.txt").write_bytes(b"nested\n")
    (source / "basic" / "link_to_hello").symlink_to("hello.txt")
    return source


def free_blocks(image, layout):
    base = layout.block_size
    width = 2 if layout.v6 else 4
    limit = 100 if layout.v6 else 50
    count_offset = 4 if layout.v6 else 6
    entries_offset = 6 if layout.v6 else 8
    count = struct.unpack_from("<H", image, base + count_offset)[0]
    stack = [
        int.from_bytes(
            image[base + entries_offset + index * width:
                  base + entries_offset + (index + 1) * width],
            "little",
        )
        for index in range(count)
    ]
    blocks = []
    while stack:
        block = stack.pop()
        blocks.append(block)
        if not stack:
            offset = block * layout.block_size
            count = struct.unpack_from("<H", image, offset)[0]
            assert count <= limit
            stack = [
                int.from_bytes(
                    image[offset + 2 + index * width:
                          offset + 2 + (index + 1) * width],
                    "little",
                )
                for index in range(count)
            ]
    return blocks


@pytest.mark.parametrize("format_name", ["v6", "32v", "v10"])
def test_generated_image_verifies_and_has_consistent_superblock(tmp_path, format_name):
    source = source_tree(tmp_path)
    output = tmp_path / f"basic.{format_name}"
    layout = mkresearchunix.LAYOUTS[format_name]

    mkresearchunix.create_image(format_name, output, source)

    image = output.read_bytes()
    nodes = mkresearchunix.collect_tree(source, layout)
    mkresearchunix.verify_image(image, layout, nodes)
    assert len(image) == layout.total_bytes
    assert struct.unpack_from("<H", image, layout.block_size)[0] >= 3
    if layout.v6:
        blocks = struct.unpack_from("<H", image, layout.block_size + 2)[0]
    else:
        blocks = struct.unpack_from("<I", image, layout.block_size + 2)[0]
    assert blocks == layout.total_bytes // layout.block_size
    allocated_end = max(block for node in nodes
                        for block in mkresearchunix.inode_fields(
                            image, layout, node.inode
                        )[2]) + 1
    assert set(free_blocks(image, layout)) == set(range(allocated_end, blocks))


def test_tree_omits_symlinks_and_truncates_names(tmp_path):
    source = source_tree(tmp_path)
    nodes = mkresearchunix.collect_tree(source, mkresearchunix.LAYOUTS["v6"])
    names = {node.name for node in nodes}

    assert "link_to_hello" not in names
    assert "file_in_dir.tx" in names


def test_truncated_names_must_remain_unique(tmp_path):
    source = tmp_path / "source"
    source.mkdir()
    (source / "12345678901234-a").write_bytes(b"a")
    (source / "12345678901234-b").write_bytes(b"b")

    with pytest.raises(ValueError, match="names collide"):
        mkresearchunix.collect_tree(source, mkresearchunix.LAYOUTS["32v"])
