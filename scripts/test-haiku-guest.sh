#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BOOT_IMAGE=$PROJECT_ROOT/build/bin/qemu/x86_64-haiku/r1beta5/boot/haiku.image
NINEPFUSE=$PROJECT_ROOT/build/bin/x86_64-linux-musl/9pfuse
RUNNER=$PROJECT_ROOT/src/qemount_build/builder/run/qemu-haiku/run.sh
PROBE=$PROJECT_ROOT/scripts/probe_9p_socket.py
TEMPLATE=$PROJECT_ROOT/build/data/templates/basic.tar
LOG_DIR=$PROJECT_ROOT/build/logs/bin/qemu/x86_64-haiku/r1beta5/integration
TEMP_PARENT=${QEMOUNT_TEST_TMPDIR:-${TMPDIR:-/tmp}}

for command in qemu-system-x86_64 python3 timeout cmp tar cp find mountpoint dd; do
    if ! command -v "$command" >/dev/null; then
        echo "Required command not found: $command" >&2
        exit 1
    fi
done

if command -v fusermount3 >/dev/null; then
    FUSERMOUNT=$(command -v fusermount3)
elif command -v fusermount >/dev/null; then
    FUSERMOUNT=$(command -v fusermount)
else
    echo "Neither fusermount3 nor fusermount is installed" >&2
    exit 1
fi

for required_file in "$BOOT_IMAGE" "$NINEPFUSE" "$RUNNER" "$PROBE" "$TEMPLATE"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Required file not found: $required_file" >&2
        exit 1
    fi
done

fixtures=(
    beos-bfs
    fat12
    fat16
    fat32
    ext2
)

mkdir -p "$LOG_DIR" "$TEMP_PARENT"
WORK_DIR=$(mktemp -d "$TEMP_PARENT/qemount-haiku-test.XXXXXXXX")
QEMU_PID=
MOUNT_POINT=

cleanup_case() {
    if [[ -n "$MOUNT_POINT" ]] && mountpoint -q "$MOUNT_POINT"; then
        "$FUSERMOUNT" -u "$MOUNT_POINT" || true
    fi
    if [[ -n "$QEMU_PID" ]] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    QEMU_PID=
    MOUNT_POINT=
}

cleanup_all() {
    cleanup_case
    rm -rf "$WORK_DIR"
}
trap cleanup_all EXIT INT TERM

mkdir -p "$WORK_DIR/expected"
tar -xf "$TEMPLATE" -C "$WORK_DIR/expected"

for filesystem in "${fixtures[@]}"; do
    fixture=$PROJECT_ROOT/build/data/fs/basic.$filesystem
    if [[ ! -f "$fixture" ]]; then
        echo "Fixture not found: $fixture" >&2
        exit 1
    fi

    case_dir=$WORK_DIR/$filesystem
    target_image=$case_dir/target.image
    socket_path=$case_dir/9p.sock
    MOUNT_POINT=$case_dir/mount
    log_file=$LOG_DIR/$filesystem.log

    mkdir -p "$MOUNT_POINT"
    cp --reflink=auto "$fixture" "$target_image"

    echo "Testing Haiku with $filesystem"
    "$RUNNER" "$BOOT_IMAGE" -i "$target_image" -s "$socket_path" \
        >"$log_file" 2>&1 &
    QEMU_PID=$!

    if ! timeout 180 python3 "$PROBE" "$socket_path" --timeout 170 \
        >>"$log_file" 2>&1; then
        echo "9P probe failed for $filesystem; see $log_file" >&2
        exit 1
    fi

    # A serial port has no connection boundary, so the probe clunks its fid
    # before the FUSE client starts a fresh protocol negotiation.
    sleep 2
    if ! timeout 30 "$NINEPFUSE" -n 1 "$socket_path" "$MOUNT_POINT" \
        >>"$log_file" 2>&1; then
        echo "9pfuse failed for $filesystem; see $log_file" >&2
        exit 1
    fi

    target_root=$(find "$MOUNT_POINT" -mindepth 3 -maxdepth 3 \
        -type f -path '*/basic/hello.txt' -printf '%h\n' -quit)
    if [[ -z "$target_root" ]]; then
        echo "Mounted $filesystem volume was not found; see $log_file" >&2
        exit 1
    fi
    target_root=${target_root%/basic}

    cmp "$WORK_DIR/expected/basic/hello.txt" "$target_root/basic/hello.txt"
    cmp "$WORK_DIR/expected/basic/script.sh" "$target_root/basic/script.sh"
    cmp "$WORK_DIR/expected/basic/nested_dir/file_in_dir.txt" \
        "$target_root/basic/nested_dir/file_in_dir.txt"

    dd if=/dev/zero of="$case_dir/write-test.bin" bs=65536 count=1 status=none
    cp "$case_dir/write-test.bin" "$target_root/qemount-write-test.bin"
    cmp "$case_dir/write-test.bin" "$target_root/qemount-write-test.bin"
    rm "$target_root/qemount-write-test.bin"
    if [[ -e "$target_root/qemount-write-test.bin" ]]; then
        echo "Delete did not persist for $filesystem" >&2
        exit 1
    fi

    "$FUSERMOUNT" -u "$MOUNT_POINT"
    kill "$QEMU_PID"
    wait "$QEMU_PID" 2>/dev/null || true
    QEMU_PID=
    MOUNT_POINT=
    echo "Passed: $filesystem"
done

echo "All Haiku guest integration cases passed"
