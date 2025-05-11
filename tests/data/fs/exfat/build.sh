# testdata/images/exfat/build.sh
#!/bin/sh
set -e

OUTPUT_PATH="$1"

# Extract base name (e.g. basic.exfat -> basic)
BASE_NAME=$(basename "$OUTPUT_PATH" .exfat)

# Extract template tar
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"
mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Create exFAT image
truncate -s 128M /tmp/output.exfat
mkfs.exfat /tmp/output.exfat

# Try to mount and populate, fail if we can't
mkdir -p /tmp/mount
if ! mount.exfat-fuse /tmp/output.exfat /tmp/mount; then
    echo "Error: Cannot mount exFAT filesystem to populate it" >&2
    echo "This may require additional privileges or capabilities" >&2
    exit 1
fi

cp -r /tmp/template/* /tmp/mount/
fusermount -u /tmp/mount

# Copy to output
mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.exfat "/host/build/$OUTPUT_PATH"