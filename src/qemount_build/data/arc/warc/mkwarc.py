"""Create a minimal WARC file from template files."""

import sys
import tarfile
import uuid
from datetime import datetime, timezone


def write_warc(output_path, tar_path):
    files = []
    with tarfile.open(tar_path) as tf:
        for member in tf.getmembers():
            if member.isfile():
                f = tf.extractfile(member)
                if f:
                    files.append((member.name, f.read()))

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(output_path, "wb") as out:
        # Warcinfo record
        warcinfo_id = f"<urn:uuid:{uuid.uuid4()}>"
        warcinfo_body = b"software: qemount-build\r\n"
        warcinfo_header = (
            f"WARC/1.0\r\n"
            f"WARC-Type: warcinfo\r\n"
            f"WARC-Date: {now}\r\n"
            f"WARC-Record-ID: {warcinfo_id}\r\n"
            f"Content-Type: application/warc-fields\r\n"
            f"Content-Length: {len(warcinfo_body)}\r\n"
            f"\r\n"
        ).encode("ascii")
        out.write(warcinfo_header)
        out.write(warcinfo_body)
        out.write(b"\r\n\r\n")

        # Resource record for each file
        for name, data in files:
            record_id = f"<urn:uuid:{uuid.uuid4()}>"
            header = (
                f"WARC/1.0\r\n"
                f"WARC-Type: resource\r\n"
                f"WARC-Date: {now}\r\n"
                f"WARC-Record-ID: {record_id}\r\n"
                f"WARC-Target-URI: file:///{name}\r\n"
                f"Content-Type: application/octet-stream\r\n"
                f"Content-Length: {len(data)}\r\n"
                f"\r\n"
            ).encode("ascii")
            out.write(header)
            out.write(data)
            out.write(b"\r\n\r\n")


if __name__ == "__main__":
    write_warc(sys.argv[1], sys.argv[2])
