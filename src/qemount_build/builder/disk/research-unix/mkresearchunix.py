#!/usr/bin/env python3
"""Create small, deterministic Research Unix filesystem fixtures.

The generated images cover the layouts consumed by 9front's v6fs, 32vfs and
v10fs readers.  They deliberately support only the direct-block range needed
by test fixtures; this is a fixture generator, not a replacement for the
historical mkfs programs.
"""

from __future__ import annotations

import argparse
import stat
import struct
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Layout:
    name: str
    block_size: int
    inode_size: int
    root_inode: int
    directory_mode: int
    regular_mode: int
    direct_blocks: int
    total_bytes: int
    v6: bool = False


LAYOUTS = {
    "v6": Layout("v6", 512, 32, 1, 0o140000, 0o100000, 8, 1 << 20, True),
    "32v": Layout("32v", 512, 64, 2, 0o040000, 0o100000, 10, 1 << 20),
    "v10": Layout("v10", 4096, 64, 2, 0o040000, 0o100000, 10, 4 << 20),
}

NAME_LENGTH = 14


@dataclass
class Node:
    path: Path
    name: str
    inode: int
    parent_inode: int
    mode: int
    children: list["Node"]
    data: bytes
    blocks: list[int]

    @property
    def is_directory(self) -> bool:
        return bool(self.children) or self.path.is_dir()


def encoded_name(name: str) -> bytes:
    try:
        raw = name.encode("ascii")
    except UnicodeEncodeError as error:
        raise ValueError(f"Research Unix names must be ASCII: {name!r}") from error
    if not raw or len(raw) > NAME_LENGTH or b"/" in raw or b"\0" in raw:
        raise ValueError(f"invalid Research Unix name: {name!r}")
    return raw.ljust(NAME_LENGTH, b"\0")


def disk_name(name: str) -> str:
    try:
        raw = name.encode("ascii")
    except UnicodeEncodeError as error:
        raise ValueError(f"Research Unix names must be ASCII: {name!r}") from error
    if not raw or b"/" in raw or b"\0" in raw:
        raise ValueError(f"invalid Research Unix name: {name!r}")
    return raw[:NAME_LENGTH].decode("ascii")


def collect_tree(source: Path, layout: Layout) -> list[Node]:
    nodes: list[Node] = []
    next_inode = layout.root_inode

    def add(path: Path, name: str, parent_inode: int) -> Node | None:
        nonlocal next_inode
        if path.is_symlink():
            return None
        encoded_name(name) if name else None
        inode = next_inode
        next_inode += 1
        host_mode = path.stat().st_mode
        permissions = stat.S_IMODE(host_mode) & 0o777
        node = Node(path, name, inode, parent_inode, permissions, [], b"", [])
        nodes.append(node)
        if path.is_dir():
            node.mode |= layout.directory_mode
            names: set[str] = set()
            for child in sorted(path.iterdir(), key=lambda item: item.name):
                if child.is_symlink():
                    continue
                name_on_disk = disk_name(child.name)
                if name_on_disk in names:
                    raise ValueError(
                        f"names collide after {NAME_LENGTH}-byte truncation in {path}: "
                        f"{child.name!r}"
                    )
                names.add(name_on_disk)
                child_node = add(child, name_on_disk, inode)
                if child_node is not None:
                    node.children.append(child_node)
        elif path.is_file():
            node.mode |= layout.regular_mode
            node.data = path.read_bytes()
        else:
            raise ValueError(f"unsupported fixture entry: {path}")
        return node

    root = Node(source, "", next_inode, next_inode, layout.directory_mode | 0o755,
                [], b"", [])
    nodes.append(root)
    next_inode += 1
    names: set[str] = set()
    for child in sorted(source.iterdir(), key=lambda item: item.name):
        if child.is_symlink():
            continue
        name_on_disk = disk_name(child.name)
        if name_on_disk in names:
            raise ValueError(
                f"names collide after {NAME_LENGTH}-byte truncation in {source}: "
                f"{child.name!r}"
            )
        names.add(name_on_disk)
        child_node = add(child, name_on_disk, root.inode)
        if child_node is not None:
            root.children.append(child_node)
    return nodes


def directory_data(node: Node) -> bytes:
    entries = [(node.inode, "."), (node.parent_inode, "..")]
    entries.extend((child.inode, child.name) for child in node.children)
    return b"".join(struct.pack("<H", inode) + encoded_name(name)
                    for inode, name in entries)


def write_free_blocks(image: bytearray, layout: Layout,
                      first_free: int) -> list[int]:
    total_blocks = len(image) // layout.block_size
    limit = 100 if layout.v6 else 50
    width = 2 if layout.v6 else 4
    stack: list[int] = []
    for block in range(total_blocks - 1, first_free - 1, -1):
        if len(stack) == limit:
            offset = block * layout.block_size
            struct.pack_into("<H", image, offset, len(stack))
            for index, free_block in enumerate(stack):
                image[offset + 2 + index * width:offset + 2 + (index + 1) * width] = (
                    free_block.to_bytes(width, "little")
                )
            stack.clear()
        stack.append(block)
    return stack


def write_superblock(image: bytearray, layout: Layout, data_start: int,
                     used_blocks: int, nodes: list[Node]) -> None:
    offset = layout.block_size
    total_blocks = len(image) // layout.block_size
    free_blocks = write_free_blocks(image, layout, used_blocks)
    per_block = layout.block_size // layout.inode_size
    inode_capacity = (data_start - 2) * per_block
    allocated = {node.inode for node in nodes}
    first_inode = 1 if layout.v6 else 2
    free_inodes = [inode for inode in range(first_inode, inode_capacity + 1)
                   if inode not in allocated][:100]

    struct.pack_into("<H", image, offset, data_start)
    if layout.v6:
        struct.pack_into("<H", image, offset + 2, total_blocks)
        struct.pack_into("<H", image, offset + 4, len(free_blocks))
        for index, block in enumerate(free_blocks):
            struct.pack_into("<H", image, offset + 6 + index * 2, block)
        struct.pack_into("<H", image, offset + 206, len(free_inodes))
        for index, inode in enumerate(free_inodes):
            struct.pack_into("<H", image, offset + 208 + index * 2, inode)
    else:
        struct.pack_into("<I", image, offset + 2, total_blocks)
        struct.pack_into("<H", image, offset + 6, len(free_blocks))
        for index, block in enumerate(free_blocks):
            struct.pack_into("<I", image, offset + 8 + index * 4, block)
        struct.pack_into("<H", image, offset + 208, len(free_inodes))
        for index, inode in enumerate(free_inodes):
            struct.pack_into("<H", image, offset + 210 + index * 2, inode)
        struct.pack_into("<I", image, offset + 418, total_blocks - used_blocks)
        struct.pack_into("<H", image, offset + 422,
                         inode_capacity - len(allocated) - (first_inode - 1))


def pack_addresses(blocks: list[int], count: int) -> bytes:
    addresses = bytearray(40)
    for index, block in enumerate(blocks):
        if index >= count:
            raise ValueError("fixture exceeds the direct-block range")
        addresses[index * 3:index * 3 + 3] = block.to_bytes(3, "little")
    return bytes(addresses)


def write_inode(image: bytearray, layout: Layout, node: Node) -> None:
    per_block = layout.block_size // layout.inode_size
    block = 2 + (node.inode - 1) // per_block
    offset = block * layout.block_size + (node.inode - 1) % per_block * layout.inode_size
    data_size = len(directory_data(node)) if node.is_directory else len(node.data)

    links = 1
    if node.is_directory:
        links = 2 + sum(child.is_directory for child in node.children)

    if layout.v6:
        if data_size >= 1 << 24:
            raise ValueError("V6 fixture file is too large")
        struct.pack_into("<HBBBBH", image, offset, node.mode, links, 0, 0,
                         data_size >> 16, data_size & 0xFFFF)
        for index, data_block in enumerate(node.blocks):
            if index >= layout.direct_blocks:
                raise ValueError("fixture exceeds the V6 direct-block range")
            struct.pack_into("<H", image, offset + 8 + index * 2, data_block)
        return

    struct.pack_into("<HHHHI", image, offset, node.mode, links, 0, 0, data_size)
    image[offset + 12:offset + 52] = pack_addresses(node.blocks, layout.direct_blocks)


def create_image(format_name: str, output: Path, source: Path) -> None:
    layout = LAYOUTS[format_name]
    nodes = collect_tree(source, layout)
    per_block = layout.block_size // layout.inode_size
    inode_blocks = (max(node.inode for node in nodes) + per_block - 1) // per_block
    next_block = 2 + inode_blocks
    image = bytearray(layout.total_bytes)

    for node in nodes:
        data = directory_data(node) if node.is_directory else node.data
        count = max(1, (len(data) + layout.block_size - 1) // layout.block_size)
        if count > layout.direct_blocks:
            raise ValueError(f"{node.path} exceeds the direct-block range")
        node.blocks = list(range(next_block, next_block + count))
        next_block += count
        if next_block * layout.block_size > len(image):
            raise ValueError("fixture does not fit in the image")
        for index, block in enumerate(node.blocks):
            chunk = data[index * layout.block_size:(index + 1) * layout.block_size]
            start = block * layout.block_size
            image[start:start + len(chunk)] = chunk

    write_superblock(image, layout, 2 + inode_blocks, next_block, nodes)
    for node in nodes:
        write_inode(image, layout, node)

    verify_image(image, layout, nodes)
    output.write_bytes(image)


def inode_fields(image: bytes, layout: Layout, inode: int) -> tuple[int, int, list[int]]:
    per_block = layout.block_size // layout.inode_size
    offset = (2 + (inode - 1) // per_block) * layout.block_size
    offset += (inode - 1) % per_block * layout.inode_size
    mode = struct.unpack_from("<H", image, offset)[0]
    if layout.v6:
        size = image[offset + 5] << 16 | struct.unpack_from("<H", image, offset + 6)[0]
        blocks = list(struct.unpack_from("<8H", image, offset + 8))
    else:
        size = struct.unpack_from("<I", image, offset + 8)[0]
        blocks = [int.from_bytes(image[offset + 12 + index * 3:offset + 15 + index * 3],
                                 "little") for index in range(13)]
    return mode, size, [block for block in blocks if block]


def verify_image(image: bytes, layout: Layout, nodes: list[Node]) -> None:
    for node in nodes:
        mode, size, blocks = inode_fields(image, layout, node.inode)
        expected = directory_data(node) if node.is_directory else node.data
        if (mode != node.mode or size != len(expected)
                or (node.blocks and blocks != node.blocks)):
            raise AssertionError(f"inode verification failed: {node.path}")
        actual = b"".join(image[block * layout.block_size:(block + 1) * layout.block_size]
                          for block in blocks)[:size]
        if actual != expected:
            raise AssertionError(f"data verification failed: {node.path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("format", choices=LAYOUTS)
    parser.add_argument("output", type=Path)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    if not args.source.is_dir():
        parser.error(f"source is not a directory: {args.source}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    create_image(args.format, args.output, args.source)


if __name__ == "__main__":
    main()
