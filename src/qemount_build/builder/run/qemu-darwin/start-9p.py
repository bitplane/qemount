#!/usr/bin/env python3

import argparse
import base64
import binascii
import socket
import struct
import sys
import time


READY = b"QEMOUNT_9P_READY"
STREAM_READY = b"Q9!\n"
RECORD_PREFIX = b"Q9:"
BYTE_INTERVAL = 0.001


def send_slow(channel: socket.socket, data: bytes) -> None:
    for byte in data:
        channel.sendall(bytes((byte,)))
        time.sleep(BYTE_INTERVAL)


def connect(path: str, timeout: float) -> socket.socket:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        channel = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            channel.connect(path)
            channel.settimeout(1)
            return channel
        except (FileNotFoundError, ConnectionRefusedError):
            channel.close()
            time.sleep(0.1)
    raise TimeoutError("timed out connecting to the PureDarwin console")


def read_until(
    channel: socket.socket,
    needle: bytes,
    timeout: float,
    received: bytearray,
) -> None:
    deadline = time.monotonic() + timeout
    while needle not in received:
        if time.monotonic() >= deadline:
            raise TimeoutError(f"timed out waiting for {needle!r}")
        try:
            chunk = channel.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            raise RuntimeError("PureDarwin console closed")
        sys.stdout.buffer.write(chunk)
        sys.stdout.buffer.flush()
        received.extend(chunk)
        if len(received) > 65536:
            del received[:-32768]
    del received[: received.index(needle) + len(needle)]


def read_exact(channel: socket.socket, size: int) -> bytes:
    data = bytearray()
    while len(data) < size:
        chunk = channel.recv(size - len(data))
        if not chunk:
            raise EOFError
        data.extend(chunk)
    return bytes(data)


def read_message(channel: socket.socket) -> bytes:
    header = read_exact(channel, 4)
    size = struct.unpack("<I", header)[0]
    if size < 7 or size > 16 * 1024 * 1024:
        raise RuntimeError(f"invalid 9P message size: {size}")
    return header + read_exact(channel, size - 4)


class ArmoredStream:
    def __init__(self, channel: socket.socket) -> None:
        self.channel = channel
        self.decoded = bytearray()
        self.wire = bytearray()

    def send(self, data: bytes) -> None:
        record = RECORD_PREFIX + base64.b64encode(data) + b"\n"
        send_slow(self.channel, record)

    def _fill(self) -> None:
        while b"\n" not in self.wire:
            chunk = self.channel.recv(4096)
            if not chunk:
                raise EOFError
            self.wire.extend(chunk)
        line, _, remainder = self.wire.partition(b"\n")
        self.wire = bytearray(remainder)
        line = line.strip(b"\r")
        if line.startswith(RECORD_PREFIX):
            try:
                self.decoded.extend(base64.b64decode(line[len(RECORD_PREFIX):], validate=True))
            except binascii.Error as error:
                raise RuntimeError("invalid stream64 record") from error

    def read_exact(self, size: int) -> bytes:
        while len(self.decoded) < size:
            self._fill()
        result = bytes(self.decoded[:size])
        del self.decoded[:size]
        return result

    def read_message(self) -> bytes:
        header = self.read_exact(4)
        size = struct.unpack("<I", header)[0]
        if size < 7 or size > 16 * 1024 * 1024:
            raise RuntimeError(f"invalid 9P message size: {size}")
        return header + self.read_exact(size - 4)


def relay_client(client: socket.socket, guest: ArmoredStream) -> None:
    while True:
        try:
            request = read_message(client)
        except EOFError:
            return
        guest.send(request)
        response = guest.read_message()
        try:
            client.sendall(response)
        except BrokenPipeError:
            return


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("backend_socket")
    parser.add_argument("public_socket")
    parser.add_argument("--timeout", type=float, default=180)
    args = parser.parse_args()

    with connect(args.backend_socket, args.timeout) as channel:
        received = bytearray()
        read_until(channel, READY, args.timeout, received)
        read_until(channel, STREAM_READY, 10, received)
        channel.settimeout(None)
        print(flush=True)
        guest = ArmoredStream(channel)

        listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        listener.bind(args.public_socket)
        listener.listen(1)
        with listener:
            while True:
                client, _ = listener.accept()
                with client:
                    relay_client(client, guest)


if __name__ == "__main__":
    main()
