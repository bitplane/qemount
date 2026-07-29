#!/bin/sh
set -eu

if [ "$#" -lt 7 ]; then
    echo "usage: run-until-marker MARKER SERIAL_LOG PROCESS_LOG TIMEOUT GRACE -- COMMAND..." >&2
    exit 2
fi

marker=$1
serial_log=$2
process_log=$3
timeout_seconds=$4
grace_seconds=$5
shift 5

if [ "$1" != "--" ]; then
    echo "run-until-marker: expected -- before command" >&2
    exit 2
fi
shift

: >"$serial_log"
"$@" >"$process_log" 2>&1 &
process_id=$!

cleanup()
{
    if kill -0 "$process_id" 2>/dev/null; then
        kill "$process_id" 2>/dev/null || true
    fi
    wait "$process_id" 2>/dev/null || true
}
trap cleanup 0
trap 'exit 129' 1
trap 'exit 130' 2
trap 'exit 143' 15

completed=false
second=0
while [ "$second" -lt "$timeout_seconds" ]; do
    if grep -q "$marker" "$serial_log"; then
        completed=true
        break
    fi
    if ! kill -0 "$process_id" 2>/dev/null; then
        break
    fi
    sleep 1
    second=$((second + 1))
done

if [ "$completed" = true ]; then
    # The guest emits its marker immediately before Shutdown. Give dos.library
    # time to flush filesystem buffers before terminating an emulation backend
    # whose virtual power-off implementation does not exit.
    sleep "$grace_seconds"
fi

cleanup
trap - 0 1 2 15

if [ "$completed" != true ]; then
    echo "Marker not observed within ${timeout_seconds}s: $marker" >&2
    exit 1
fi
