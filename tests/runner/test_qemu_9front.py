import importlib.util
import io
from pathlib import Path


SCRIPT = (
    Path(__file__).parents[2]
    / "src/qemount_build/builder/run/qemu-9front/serial_relay.py"
)


def load_serial_relay():
    spec = importlib.util.spec_from_file_location("qemu_9front_serial_relay", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_wait_for_marker_handles_split_marker(monkeypatch):
    module = load_serial_relay()

    class Channel:
        chunks = iter((b"boot [qem", b"ount] mounted /dev", b"/sdG0\r\n"))

        def recv(self, _size):
            return next(self.chunks)

    output = io.BytesIO()
    monkeypatch.setattr(module.sys, "stdout", type("Output", (), {"buffer": output})())

    module.wait_for_marker(Channel(), b"[qemount] mounted")

    assert output.getvalue() == b"boot [qemount] mounted /dev/sdG0\r\n"
