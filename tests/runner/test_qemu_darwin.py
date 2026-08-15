import importlib.util
import io
from pathlib import Path


SCRIPT = (
    Path(__file__).parents[2]
    / "src/mountin_build/builder/run/qemu-darwin/start-9p.py"
)


def load_start_9p():
    spec = importlib.util.spec_from_file_location("qemu_darwin_start_9p", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_read_until_preserves_bytes_after_marker(monkeypatch):
    module = load_start_9p()

    class Channel:
        def __init__(self):
            self.reads = 0

        def recv(self, _size):
            self.reads += 1
            return b"boot READYQ9!\n"

    output = io.BytesIO()
    monkeypatch.setattr(module.sys, "stdout", type("Output", (), {"buffer": output})())
    channel = Channel()
    received = bytearray()

    module.read_until(channel, b"READY", 1, received)
    module.read_until(channel, b"Q9!\n", 1, received)

    assert channel.reads == 1
    assert received == bytearray()
    assert output.getvalue() == b"boot READYQ9!\n"
