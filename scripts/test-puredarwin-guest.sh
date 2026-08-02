#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GUEST=${QEMOUNT_PUREDARWIN_GUEST:-$PROJECT_ROOT/build/bin/qemu/x86_64-darwin/puredarwin/appliance/puredarwin.raw}
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
    "$PROJECT_ROOT/build/data/fs/basic.hfsplus"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Required file not found: $required_file" >&2
        exit 1
    fi
done

mkdir -p "$PROJECT_ROOT/build/logs" "$PROJECT_ROOT/build/tmp"

run_case() {
    local name=$1
    local image=$2
    local expected=$3
    local socket=$PROJECT_ROOT/build/tmp/puredarwin-${name}-test.sock
    local log=$PROJECT_ROOT/build/logs/puredarwin-${name}-test.log

    "$RUNNER" "$GUEST" -i "$image" -s "$socket" >"$log" 2>&1 &
    RUNNER_PID=$!

    python3 "$PROBE" "$socket" \
        --timeout 180 \
        --read-file basic/hello.txt \
        --expect-hex "$expected"

    stop_runner
    echo "$name passed; log: $log"
}

run_case \
    hfs \
    "$PROJECT_ROOT/build/data/fs/basic.hfs" \
    48656c6c6f2c20776f726c64210d
run_case \
    hfsplus \
    "$PROJECT_ROOT/build/data/fs/basic.hfsplus" \
    48656c6c6f2c20776f726c64210a

echo "PureDarwin HFS and HFS+ serial 9P tests passed"
