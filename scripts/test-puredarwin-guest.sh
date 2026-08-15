#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GUEST=${QEMOUNT_PUREDARWIN_GUEST:-$PROJECT_ROOT/build/bin/qemu/x86_64-darwin/17.4/puredarwin.raw}
RUNNER=$PROJECT_ROOT/src/qemount_build/builder/run/qemu-darwin/run.sh
PROBE=$PROJECT_ROOT/scripts/probe_9p_socket.py
RUNNER_PID=

cleanup() {
    stop_runner
}
trap cleanup EXIT INT TERM

stop_runner() {
    if [[ -n "$RUNNER_PID" ]] && kill -0 "$RUNNER_PID" 2>/dev/null; then
        kill "$RUNNER_PID" 2>/dev/null || true
        wait "$RUNNER_PID" 2>/dev/null || true
    fi
    RUNNER_PID=
}

for required_file in \
    "$GUEST" \
    "$RUNNER" \
    "$PROBE" \
    "$PROJECT_ROOT/build/data/fs/basic.hfs" \
    "$PROJECT_ROOT/build/data/fs/basic.hfsplus" \
    "$PROJECT_ROOT/build/data/fs/basic.hfsx" \
    "$PROJECT_ROOT/build/data/pt/hfs.mbr" \
    "$PROJECT_ROOT/build/data/pt/hfsplus.gpt" \
    "$PROJECT_ROOT/build/data/pt/basic.apm"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Required file not found: $required_file" >&2
        exit 1
    fi
done

mkdir -p "$PROJECT_ROOT/build/logs" "$PROJECT_ROOT/build/tmp"

run_case() {
    local name=$1
    local image=$2
    shift 2
    local socket=$PROJECT_ROOT/build/tmp/puredarwin-${name}-test.sock
    local log=$PROJECT_ROOT/build/logs/puredarwin-${name}-test.log

    "$RUNNER" "$GUEST" -i "$image" -s "$socket" >"$log" 2>&1 &
    RUNNER_PID=$!

    while [[ $# -gt 0 ]]; do
        local path=$1
        local expected=$2
        shift 2
        python3 "$PROBE" "$socket" \
            --timeout 180 \
            --read-file "$path" \
            --expect-hex "$expected"
    done

    stop_runner
    echo "$name passed; log: $log"
}

run_case \
    hfs \
    "$PROJECT_ROOT/build/data/fs/basic.hfs" \
    basic/hello.txt \
    48656c6c6f2c20776f726c64210d
run_case \
    hfsplus \
    "$PROJECT_ROOT/build/data/fs/basic.hfsplus" \
    basic/hello.txt \
    48656c6c6f2c20776f726c64210a
run_case \
    hfsx \
    "$PROJECT_ROOT/build/data/fs/basic.hfsx" \
    basic/case.txt \
    6c6f77657220636173650a \
    basic/CASE.txt \
    757070657220636173650a
run_case \
    mbr-hfs \
    "$PROJECT_ROOT/build/data/pt/hfs.mbr" \
    basic/hello.txt \
    48656c6c6f2c20776f726c64210d
run_case \
    gpt-hfsplus \
    "$PROJECT_ROOT/build/data/pt/hfsplus.gpt" \
    basic/hello.txt \
    48656c6c6f2c20776f726c64210a
run_case \
    apm-hfs \
    "$PROJECT_ROOT/build/data/pt/basic.apm" \
    basic/hello.txt \
    48656c6c6f2c20776f726c64210d

echo "PureDarwin raw, MBR, GPT and APM serial 9P tests passed"
