#!/usr/bin/env python3
"""Perform a minimal read-only 9P2000.u probe over a Unix stream socket."""

import argparse
import socket
import struct
import time


TVERSION = 100
RVERSION = 101
TATTACH = 104
RATTACH = 105
RERROR = 107
TOPEN = 112
ROPEN = 113
TREAD = 116
RREAD = 117
TCLUNK = 120
RCLUNK = 121
NOTAG = 0xFFFF
NOFID = 0xFFFFFFFF


def p9_string(value: str) -> bytes:
    encoded = value.encode()
    return struct.pack("<H", len(encoded)) + encoded


def request(sock: socket.socket, message_type: int, tag: int, payload: bytes) -> bytes:
    message = struct.pack("<BH", message_type, tag) + payload
    sock.sendall(struct.pack("<I", len(message) + 4) + message)

    size = struct.unpack("<I", receive(sock, 4))[0]
    response = receive(sock, size - 4)
    response_type, response_tag = struct.unpack_from("<BH", response)
    if response_type == RERROR:
        error_length = struct.unpack_from("<H", response, 3)[0]
        error = response[5:5 + error_length].decode(errors="replace")
        raise RuntimeError(f"9P error for tag {response_tag}: {error}")
    if response_tag != tag:
        raise RuntimeError(f"response tag {response_tag} does not match {tag}")
    return response


def receive(sock: socket.socket, size: int) -> bytes:
    chunks = bytearray()
    while len(chunks) < size:
        chunk = sock.recv(size - len(chunks))
        if not chunk:
            raise RuntimeError("9P stream closed during a response")
        chunks.extend(chunk)
    return bytes(chunks)


def connect(path: str, timeout: float) -> socket.socket:
    deadline = time.monotonic() + timeout
    while True:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            sock.connect(path)
            return sock
        except OSError:
            sock.close()
            if time.monotonic() >= deadline:
                raise
            time.sleep(0.1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("socket", help="QEMU serial Unix socket")
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument(
        "--connect-delay",
        type=float,
        default=0,
        help="seconds to wait for the guest before opening the serial socket",
    )
    parser.add_argument(
        "--request-delay",
        type=float,
        default=0,
        help="seconds to wait between successful 9P requests",
    )
    args = parser.parse_args()

    time.sleep(args.connect_delay)
    with connect(args.socket, args.timeout) as sock:
        sock.settimeout(args.timeout)

        response = request(
            sock,
            TVERSION,
            NOTAG,
            struct.pack("<I", 8192) + p9_string("9P2000.u"),
        )
        if response[0] != RVERSION:
            raise RuntimeError(f"expected Rversion, received type {response[0]}")
        msize = struct.unpack_from("<I", response, 3)[0]
        version_length = struct.unpack_from("<H", response, 7)[0]
        version = response[9:9 + version_length].decode()
        print(f"negotiated {version} with msize {msize}", flush=True)
        time.sleep(args.request_delay)

        response = request(
            sock,
            TATTACH,
            1,
            struct.pack("<II", 1, NOFID)
            + p9_string("none")
            + p9_string("")
            + struct.pack("<I", NOFID),
        )
        if response[0] != RATTACH:
            raise RuntimeError(f"expected Rattach, received type {response[0]}")
        print("attached root fid", flush=True)
        time.sleep(args.request_delay)

        response = request(sock, TOPEN, 2, struct.pack("<IB", 1, 0))
        if response[0] != ROPEN:
            raise RuntimeError(f"expected Ropen, received type {response[0]}")
        print("opened root fid", flush=True)
        time.sleep(args.request_delay)

        response = request(
            sock,
            TREAD,
            3,
            struct.pack("<IQI", 1, 0, min(msize - 24, 8168)),
        )
        if response[0] != RREAD:
            raise RuntimeError(f"expected Rread, received type {response[0]}")
        count = struct.unpack_from("<I", response, 3)[0]
        data = response[7:]
        if count != len(data) or count == 0:
            raise RuntimeError(
                f"invalid root read: declared {count} bytes, received {len(data)}"
            )

        print(f"read {count} bytes from the attached root directory")

        response = request(sock, TCLUNK, 4, struct.pack("<I", 1))
        if response[0] != RCLUNK:
            raise RuntimeError(f"expected Rclunk, received type {response[0]}")
        print("clunked root fid")


if __name__ == "__main__":
    main()
