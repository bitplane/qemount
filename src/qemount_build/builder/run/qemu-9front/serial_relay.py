#!/usr/bin/env python3

import os
import select
import socket
import sys
import time


def connect(path: str, timeout: float = 30.0) -> socket.socket:
    deadline = time.monotonic() + timeout
    while True:
        stream = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            stream.connect(path)
            return stream
        except (FileNotFoundError, ConnectionRefusedError):
            stream.close()
            if time.monotonic() >= deadline:
                raise TimeoutError(f"timed out connecting to QEMU UART: {path}")
            time.sleep(0.05)


def wait_for_marker(stream: socket.socket, marker: bytes) -> None:
    pending = b""
    while True:
        data = stream.recv(4096)
        if not data:
            raise ConnectionError("QEMU UART closed before the appliance was ready")
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
        pending += data
        marker_at = pending.find(marker)
        if marker_at >= 0:
            if b"\n" in pending[marker_at + len(marker) :]:
                return
            pending = pending[marker_at:]
        else:
            pending = pending[-(len(marker) - 1) :]


def forward(guest: socket.socket, client: socket.socket) -> None:
    peers = {guest: client, client: guest}
    while peers:
        readable, _, _ = select.select(peers, [], [])
        for source in readable:
            data = source.recv(65536)
            if not data:
                return
            peers[source].sendall(data)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} internal-socket public-socket")

    internal_path, public_path = sys.argv[1:]
    listener = None
    stream = None
    try:
        stream = connect(internal_path)
        wait_for_marker(stream, b"[qemount] export ready")

        try:
            os.unlink(public_path)
        except FileNotFoundError:
            pass
        listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        listener.bind(public_path)
        listener.listen(1)
        print(f"9P ready: {public_path}", flush=True)

        client, _ = listener.accept()
        with client:
            forward(stream, client)
    finally:
        if listener is not None:
            listener.close()
        if stream is not None:
            stream.close()
        try:
            os.unlink(public_path)
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()
