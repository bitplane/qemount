#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)
QEMU=$PROJECT_ROOT/build/bin/qemu-system/x86_64-linux-musl/qemu-system-x86_64
FIRMWARE=$PROJECT_ROOT/build/bin/qemu-system/firmware
START_9P=$(dirname "${BASH_SOURCE[0]}")/start-9p.py

usage() {
    cat <<EOF
Usage: $0 <boot-image> -i <target-image> [-s <socket>]

Options:
  -i <image>    Attach the single HFS or HFS+ image to inspect
  -s <socket>   9P serial socket path (default: build/tmp/puredarwin-9p.sock)
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

BOOT_IMAGE=$1
shift
TARGET_IMAGE=
SOCKET_PATH=$PROJECT_ROOT/build/tmp/puredarwin-9p.sock

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for -i" >&2
                exit 1
            fi
            TARGET_IMAGE=$2
            shift 2
            ;;
        -s)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for -s" >&2
                exit 1
            fi
            SOCKET_PATH=$2
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET_IMAGE" ]]; then
    echo "A target image is required" >&2
    exit 1
fi
for required_file in "$BOOT_IMAGE" "$TARGET_IMAGE" "$QEMU" "$START_9P"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Required file not found: $required_file" >&2
        exit 1
    fi
done
if [[ "$SOCKET_PATH" == / || -d "$SOCKET_PATH" ]]; then
    echo "Invalid socket path: $SOCKET_PATH" >&2
    exit 1
fi
BACKEND_PATH=$SOCKET_PATH.backend

mkdir -p "$(dirname "$SOCKET_PATH")"
rm -f "$SOCKET_PATH" "$BACKEND_PATH"

QEMU_PID=
PROXY_PID=
cleanup() {
    if [[ -n "$PROXY_PID" ]] && kill -0 "$PROXY_PID" 2>/dev/null; then
        kill "$PROXY_PID" 2>/dev/null || true
        wait "$PROXY_PID" 2>/dev/null || true
    fi
    if [[ -n "$QEMU_PID" ]] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    rm -f "$SOCKET_PATH" "$BACKEND_PATH"
}
trap cleanup EXIT INT TERM

"$QEMU" \
    -L "$FIRMWARE" \
    -machine pc,accel=tcg \
    -cpu Penryn \
    -smp 2 \
    -m 2048 \
    -display none \
    -monitor none \
    -no-reboot \
    -net none \
    -chardev "socket,id=serial,path=$BACKEND_PATH,server=on,wait=off" \
    -serial chardev:serial \
    -boot c \
    -drive "format=raw,file=$BOOT_IMAGE,snapshot=on,index=0" \
    -drive "format=raw,file=$TARGET_IMAGE,snapshot=on,index=1" &
QEMU_PID=$!

python3 "$START_9P" "$BACKEND_PATH" "$SOCKET_PATH" &
PROXY_PID=$!

deadline=$((SECONDS + 180))
until [[ -S "$SOCKET_PATH" ]]; do
    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
        echo "PureDarwin exited before starting simple9p" >&2
        exit 1
    fi
    if ! kill -0 "$PROXY_PID" 2>/dev/null; then
        wait "$PROXY_PID"
        exit 1
    fi
    if ((SECONDS >= deadline)); then
        echo "PureDarwin did not start simple9p within 180 seconds" >&2
        exit 1
    fi
    sleep 0.1
done

echo "9P socket: $SOCKET_PATH"
echo "Connect with: 9pfuse -n 1 $SOCKET_PATH <mountpoint>"
wait -n "$QEMU_PID" "$PROXY_PID"
