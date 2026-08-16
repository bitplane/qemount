#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BOOT_IMAGE=${MOUNTIN_HAIKU_BOOT_IMAGE:-$PROJECT_ROOT/build/bin/qemu/x86_64-haiku/r1-beta6-hrev59919+1/haiku.image}
NINEPFUSE=${MOUNTIN_HAIKU_9PFUSE:-$PROJECT_ROOT/build/bin/x86_64-linux-musl/9pfuse}
RUNNER=$PROJECT_ROOT/src/mountin/builder/run/qemu-haiku/run.sh
PROBE=$PROJECT_ROOT/scripts/probe_9p_socket.py
TEMPLATE=$PROJECT_ROOT/build/data/templates/basic.tar
LOG_DIR=$PROJECT_ROOT/build/logs/bin/qemu/x86_64-haiku/r1-beta6-hrev59919+1/integration
TEMP_PARENT=${MOUNTIN_TEST_TMPDIR:-$PROJECT_ROOT/build/tmp}
WRITE_TEST_SIZE=${MOUNTIN_HAIKU_WRITE_TEST_SIZE:-4096}
KEEP_TEST_WORK=${MOUNTIN_KEEP_TEST_WORK:-0}
FORCE_MUTATION=${MOUNTIN_HAIKU_FORCE_MUTATION:-0}
NINEPFUSE_ARGS=(-n 1)
if [[ ${MOUNTIN_HAIKU_9PFUSE_DEBUG:-0} == 1 ]]; then
    NINEPFUSE_ARGS=(-D "${NINEPFUSE_ARGS[@]}")
fi

for command in qemu-system-x86_64 python3 timeout cmp tar cp find grep mountpoint dd stat; do
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

case_spec() {
    case "$1" in
        beos-bfs)          echo "data/fs/basic.beos-bfs|1|rw|disk|posix" ;;
        btrfs)             echo "data/fs/basic.btrfs|1|ro|disk|posix" ;;
        exfat)             echo "data/fs/basic.exfat|1|ro|disk|posix" ;;
        exfat-mbr)         echo "data/pt/exfat.mbr|1|ro|disk|posix" ;;
        ext2)              echo "data/fs/basic.ext2|1|rw|disk|posix" ;;
        ext3)              echo "data/fs/basic.ext3|1|rw|disk|posix" ;;
        ext4)              echo "data/fs/basic.ext4|1|rw|disk|posix" ;;
        fat12)             echo "data/fs/basic.fat12|1|read|disk|posix" ;;
        fat16)             echo "data/fs/basic.fat16|1|read|disk|posix" ;;
        fat32)             echo "data/fs/basic.fat32|1|read|disk|posix" ;;
        iso9660)           echo "data/fs/basic.iso9660|1|ro|cdrom|iso-basic" ;;
        iso9660-joliet)    echo "data/fs/basic.joliet.iso9660|1|ro|cdrom|posix" ;;
        iso9660-rockridge) echo "data/fs/basic.rock-ridge.iso9660|1|ro|cdrom|posix" ;;
        ntfs)              echo "data/fs/basic.ntfs|1|read|disk|posix" ;;
        reiserfs)          echo "data/fs/basic.reiserfs|1|ro|disk|posix" ;;
        udf)               echo "data/fs/basic.udf-optical|1|ro|cdrom|posix" ;;
        udf-efe)           echo "data/fs/basic.udf-optical-efe|1|ro|cdrom|posix" ;;
        mbr)               echo "data/pt/basic.mbr|3|mixed|disk|posix" ;;
        mbr-extended)      echo "data/pt/extended.mbr|5|mixed|disk|posix" ;;
        gpt)               echo "data/pt/basic.gpt|5|mixed|disk|posix" ;;
        hybrid-gpt)        echo "data/pt/hybrid.gpt|2|mixed|disk|posix" ;;
        *)
            echo "Unknown Haiku integration case: $1" >&2
            return 1
            ;;
    esac
}

if (($#)); then
    cases=("$@")
else
    cases=(
        beos-bfs
        btrfs
        exfat
        exfat-mbr
        ext2
        ext3
        ext4
        fat12
        fat16
        fat32
        iso9660
        iso9660-joliet
        iso9660-rockridge
        ntfs
        reiserfs
        udf
        udf-efe
        mbr
        mbr-extended
        gpt
        hybrid-gpt
    )
fi

mkdir -p "$LOG_DIR" "$TEMP_PARENT"
WORK_DIR=$(mktemp -d "$TEMP_PARENT/mountin-haiku-test.XXXXXXXX")
QEMU_PID=
MOUNT_POINT=

cleanup_case() {
    if [[ -n "$MOUNT_POINT" ]] && mountpoint -q "$MOUNT_POINT"; then
        "$FUSERMOUNT" -u -z "$MOUNT_POINT" || true
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
    if [[ "$KEEP_TEST_WORK" == 1 ]]; then
        echo "Preserved test workspace: $WORK_DIR"
    else
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup_all EXIT INT TERM

wait_for_guest() {
    local socket_path=$1
    local log_file=$2
    local deadline=$((SECONDS + 180))

    until [[ -S "$socket_path" ]] \
        && grep -q "mountin: serving / over" "$log_file" 2>/dev/null; do
        if ! kill -0 "$QEMU_PID" 2>/dev/null; then
            echo "Haiku exited before starting 9d; see $log_file" >&2
            return 1
        fi
        if ((SECONDS >= deadline)); then
            echo "Haiku did not start 9d within 180 seconds; see $log_file" >&2
            return 1
        fi
        sleep 0.2
    done
    sleep 2
}

remove_with_guest_watch() {
    local path=$1
    local log_file=$2
    local remove_pid

    timeout --kill-after=5 60 rm "$path" &
    remove_pid=$!
    while kill -0 "$remove_pid" 2>/dev/null; do
        if grep -q '^PANIC:' "$log_file" 2>/dev/null; then
            echo "Haiku panicked while removing $path; see $log_file" >&2
            if kill -0 "$QEMU_PID" 2>/dev/null; then
                kill "$QEMU_PID" 2>/dev/null || true
                wait "$QEMU_PID" 2>/dev/null || true
            fi
            QEMU_PID=
            if mountpoint -q "$MOUNT_POINT"; then
                "$FUSERMOUNT" -u -z "$MOUNT_POINT" || true
            fi
            MOUNT_POINT=
            wait "$remove_pid" 2>/dev/null || true
            return 1
        fi
        sleep 0.2
    done
    wait "$remove_pid"
}

mkdir -p "$WORK_DIR/expected"
tar -xf "$TEMPLATE" -C "$WORK_DIR/expected"

for case_name in "${cases[@]}"; do
    IFS='|' read -r fixture_path expected_volumes access_mode target_media \
        fixture_layout \
        <<< "$(case_spec "$case_name")"
    log_suffix=
    if [[ "$FORCE_MUTATION" == 1 && "$access_mode" == read ]]; then
        access_mode=rw
        log_suffix=-mutation
    fi
    fixture=$PROJECT_ROOT/build/$fixture_path
    if [[ ! -f "$fixture" ]]; then
        echo "Fixture not found: $fixture" >&2
        exit 1
    fi

    case_dir=$WORK_DIR/$case_name
    target_image=$case_dir/target.image
    socket_path=$case_dir/9p.sock
    MOUNT_POINT=$case_dir/mount
    log_file=$LOG_DIR/$case_name$log_suffix.log

    mkdir -p "$MOUNT_POINT"
    cp --reflink=auto "$fixture" "$target_image"

    echo "Testing Haiku with $case_name"
    "$RUNNER" "$BOOT_IMAGE" -i "$target_image" -t "$target_media" \
        -s "$socket_path" \
        >"$log_file" 2>&1 &
    QEMU_PID=$!

    wait_for_guest "$socket_path" "$log_file"
    if ! timeout 45 python3 "$PROBE" "$socket_path" --timeout 40 \
        >>"$log_file" 2>&1; then
        echo "9P probe failed for $case_name; see $log_file" >&2
        exit 1
    fi

    # A serial port has no connection boundary, so the probe clunks its fid
    # before the FUSE client starts a fresh protocol negotiation.
    sleep 2
    if ! timeout 30 "$NINEPFUSE" "${NINEPFUSE_ARGS[@]}" \
        "$socket_path" "$MOUNT_POINT" \
        >>"$log_file" 2>&1; then
        echo "9pfuse failed for $case_name; see $log_file" >&2
        exit 1
    fi

    shopt -s nullglob
    mounted_files=("$MOUNT_POINT"/*/basic/hello.txt)
    volume_deadline=$((SECONDS + 30))
    while ((${#mounted_files[@]} != expected_volumes)) \
        && ((SECONDS < volume_deadline)); do
        sleep 0.2
        mounted_files=("$MOUNT_POINT"/*/basic/hello.txt)
    done
    shopt -u nullglob
    if ((${#mounted_files[@]} != expected_volumes)); then
        echo "$case_name exposed ${#mounted_files[@]} test-data volumes; expected $expected_volumes" >&2
        echo "See $log_file" >&2
        exit 1
    fi

    target_roots=()
    for mounted_file in "${mounted_files[@]}"; do
        target_root=${mounted_file%/basic/hello.txt}
        target_roots+=("$target_root")
        if ! timeout 60 cmp "$WORK_DIR/expected/basic/hello.txt" \
            "$target_root/basic/hello.txt"; then
            cp "$target_root/basic/hello.txt" \
                "$case_dir/observed-hello.txt"
            echo "Preserved mismatching file: $case_dir/observed-hello.txt" >&2
            exit 1
        fi
        timeout 60 cmp "$WORK_DIR/expected/basic/script.sh" \
            "$target_root/basic/script.sh"
        nested_path=$target_root/basic/nested_dir/file_in_dir.txt
        if [[ "$fixture_layout" == iso-basic ]]; then
            nested_path=$target_root/basic/nested_d/file_in_.txt
        fi
        timeout 60 cmp "$WORK_DIR/expected/basic/nested_dir/file_in_dir.txt" \
            "$nested_path"

        expected_file=$WORK_DIR/expected/basic/hello.txt
        observed_file=$target_root/basic/hello.txt
        dd if="$expected_file" of="$case_dir/expected-range" bs=1 skip=2 \
            count=5 status=none
        timeout 60 dd if="$observed_file" of="$case_dir/observed-range" \
            bs=1 skip=2 count=5 status=none
        cmp "$case_dir/expected-range" "$case_dir/observed-range"

        file_size=$(stat -c %s "$expected_file")
        timeout 60 dd if="$observed_file" of="$case_dir/observed-eof" \
            bs=1 skip="$file_size" count=1 status=none
        test ! -s "$case_dir/observed-eof"
    done

    if [[ "$access_mode" == rw ]]; then
        target_root=${target_roots[0]}
        dd if=/dev/zero of="$case_dir/write-test.bin" bs="$WRITE_TEST_SIZE" \
            count=1 status=none
        timeout 60 cp "$case_dir/write-test.bin" \
            "$target_root/mountin-write-test.bin"
        timeout 60 cmp "$case_dir/write-test.bin" \
            "$target_root/mountin-write-test.bin"
        if ! remove_with_guest_watch "$target_root/mountin-write-test.bin" \
            "$log_file"; then
            exit 1
        fi
        if [[ -e "$target_root/mountin-write-test.bin" ]]; then
            echo "Delete did not persist for $case_name" >&2
            exit 1
        fi
    elif [[ "$access_mode" == ro ]]; then
        target_root=${target_roots[0]}
        set +e
        timeout 30 sh -c 'printf test > "$1"' sh \
            "$target_root/mountin-write-test.txt" 2>>"$log_file"
        write_status=$?
        set -e
        if [[ "$write_status" == 0 || "$write_status" == 124 ]]; then
            echo "Read-only write did not fail cleanly for $case_name" >&2
            exit 1
        fi
        test ! -e "$target_root/mountin-write-test.txt"
    fi

    "$FUSERMOUNT" -u -z "$MOUNT_POINT"
    kill "$QEMU_PID"
    wait "$QEMU_PID" 2>/dev/null || true
    QEMU_PID=
    MOUNT_POINT=
    echo "Passed: $case_name"
done

echo "All Haiku guest integration cases passed"
