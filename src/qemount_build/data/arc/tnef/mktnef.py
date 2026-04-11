"""
Create a TNEF (winmail.dat) file from files or directories.

Usage:
    mktnef.py output.tnef file1 [file2 ...]
    mktnef.py output.tnef directory/

Wraps the given files as attachments in a valid TNEF stream with the
standard winmail.dat structure that Outlook/Exchange would produce.
"""

import os
import struct
import sys
import time

# TNEF signature
TNEF_SIGNATURE = 0x223E9F78

# Attribute levels
LVL_MESSAGE = 0x01
LVL_ATTACHMENT = 0x02

# Message-level attribute IDs
ATTR_TNEF_VERSION = 0x9006
ATTR_OEM_CODEPAGE = 0x9007
ATTR_MESSAGE_CLASS = 0x8008
ATTR_DATE_SENT = 0x8005

# Attachment-level attribute IDs
ATTR_ATTACH_TITLE = 0x8010
ATTR_ATTACH_DATA = 0x800F
ATTR_ATTACH_MODIFY_DATE = 0x8006
ATTR_ATTACH_RENDDATA = 0x9002


def tnef_checksum(data):
    """TNEF checksum: sum of all bytes mod 65536."""
    return sum(data) & 0xFFFF


def write_attribute(out, level, attr_id, data):
    """Write a single TNEF attribute record."""
    out.write(struct.pack("<B", level))
    out.write(struct.pack("<H", attr_id))
    out.write(struct.pack("<I", len(data)))
    out.write(data)
    out.write(struct.pack("<H", tnef_checksum(data)))


def encode_tnef_date(timestamp=None):
    """Encode a timestamp as a TNEF date (14 bytes)."""
    t = time.gmtime(timestamp or time.time())
    return struct.pack("<HHHHHHH",
                       t.tm_year, t.tm_mon, t.tm_mday,
                       t.tm_hour, t.tm_min, t.tm_sec,
                       t.tm_wday)


def renddata_default():
    """Default ATTACH_RENDDATA (attachment rendering data).

    This tells the client how to display the attachment. We use the
    standard "file attachment" type with no special rendering.
    """
    # type(2) + position(4) + width(2) + height(2) + flags(4) = 14 bytes
    return struct.pack("<HIHHH",
                       0x0001,      # atyFile
                       0xFFFFFFFF,  # position (not specified)
                       0, 0,        # width, height
                       0)           # flags


def collect_files(paths):
    """Collect files from paths, expanding directories."""
    files = []
    for path in paths:
        if os.path.isdir(path):
            for root, _, filenames in os.walk(path):
                for name in sorted(filenames):
                    full = os.path.join(root, name)
                    files.append((name, full))
        elif os.path.isfile(path):
            files.append((os.path.basename(path), path))
    return files


def write_tnef(output_path, paths):
    """Create a TNEF file containing the given files as attachments."""
    files = collect_files(paths)

    with open(output_path, "wb") as out:
        # Header: signature + legacy key
        out.write(struct.pack("<I", TNEF_SIGNATURE))
        out.write(struct.pack("<H", 0x0001))  # key

        # Message-level attributes
        write_attribute(out, LVL_MESSAGE, ATTR_TNEF_VERSION,
                        struct.pack("<I", 0x00010000))

        write_attribute(out, LVL_MESSAGE, ATTR_OEM_CODEPAGE,
                        struct.pack("<II", 65001, 0))  # UTF-8

        write_attribute(out, LVL_MESSAGE, ATTR_MESSAGE_CLASS,
                        b"IPM.Note\x00")

        write_attribute(out, LVL_MESSAGE, ATTR_DATE_SENT,
                        encode_tnef_date())

        # Attachment-level attributes for each file
        for name, path in files:
            with open(path, "rb") as f:
                data = f.read()

            mtime = os.path.getmtime(path)

            write_attribute(out, LVL_ATTACHMENT, ATTR_ATTACH_RENDDATA,
                            renddata_default())

            write_attribute(out, LVL_ATTACHMENT, ATTR_ATTACH_TITLE,
                            name.encode("ascii", errors="replace") + b"\x00")

            write_attribute(out, LVL_ATTACHMENT, ATTR_ATTACH_DATA, data)

            write_attribute(out, LVL_ATTACHMENT, ATTR_ATTACH_MODIFY_DATE,
                            encode_tnef_date(mtime))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} output.tnef file_or_dir [...]",
              file=sys.stderr)
        sys.exit(1)
    write_tnef(sys.argv[1], sys.argv[2:])
