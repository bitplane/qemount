#!/bin/bash
set -euo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

for command in git podman xz sha256sum; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command not found: $command" >&2
        exit 1
    fi
done

if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then
    echo "Refusing to archive a dirty checkout." >&2
    echo "Commit or remove all changes first so the capsule has an exact source revision." >&2
    exit 1
fi

DATE=$(date -u +%Y-%m-%d_%H-%M-%SZ)
QEMOUNT_COMMIT=$(git rev-parse HEAD)
BUILDER_IMAGE="qemount-builder"
CONTAINER_NAME="qemount-build-${DATE}-$$"
BUNDLE_FILE="$ROOT_DIR/.qemount-archive.bundle"
CONTAINER_CREATED=0
ARCHIVE_TMP=
ARCHIVE_FILE=
README_FILE=
CHECKSUM_FILE=
OUTPUT_COMPLETE=0

cleanup() {
    status=$?
    trap - EXIT

    rm -f -- "$BUNDLE_FILE"
    if [ -n "$ARCHIVE_TMP" ]; then
        rm -f -- "$ARCHIVE_TMP"
    fi
    if [ "$OUTPUT_COMPLETE" -eq 0 ]; then
        if [ -n "$ARCHIVE_FILE" ]; then
            rm -f -- "$ARCHIVE_FILE"
        fi
        if [ -n "$README_FILE" ]; then
            rm -f -- "$README_FILE"
        fi
        if [ -n "$CHECKSUM_FILE" ]; then
            rm -f -- "$CHECKSUM_FILE"
        fi
    fi
    if [ "$CONTAINER_CREATED" -eq 1 ]; then
        podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi

    exit "$status"
}
trap cleanup EXIT

ts() {
    while IFS= read -r line; do
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line"
    done
}

log_cmd() {
    local label="$1"
    shift
    echo "=== $label ===" | ts
    time "$@" 2>&1 | ts
    echo "=== $label complete ===" | ts
}

echo "=== Preparing qemount time capsule ===" | ts
echo "Source commit: $QEMOUNT_COMMIT" | ts
rm -f -- "$BUNDLE_FILE"
git bundle create "$BUNDLE_FILE" --all HEAD
git bundle verify "$BUNDLE_FILE" 2>&1 | ts

log_cmd "Building archive environment" \
    podman build \
        --build-arg "QEMOUNT_COMMIT=$QEMOUNT_COMMIT" \
        --label "org.opencontainers.image.revision=$QEMOUNT_COMMIT" \
        -f scripts/Dockerfile.archive \
        -t "$BUILDER_IMAGE" \
        .

log_cmd "Creating build container" \
    podman create --privileged --name "$CONTAINER_NAME" "$BUILDER_IMAGE"
CONTAINER_CREATED=1

log_cmd "Running build" \
    podman start --attach "$CONTAINER_NAME"

mkdir -p build/archive
ARCHIVE_FILE="build/archive/${DATE}_qemount.tar.xz"
ARCHIVE_TMP="${ARCHIVE_FILE}.tmp"
README_FILE="build/archive/${DATE}_qemount.README.md"
CHECKSUM_FILE="build/archive/${DATE}_qemount.sha256"

# Use export instead of save - exports container filesystem directly
# without the layer overhead that makes podman save pathologically slow
export_archive() {
    podman export "$CONTAINER_NAME" | xz -9 > "$ARCHIVE_TMP"
}
log_cmd "Exporting archive" \
    export_archive

log_cmd "Checking compressed archive" \
    xz -t "$ARCHIVE_TMP"

mv "$ARCHIVE_TMP" "$ARCHIVE_FILE"
ARCHIVE_TMP=
cp scripts/TIME_CAPSULE.md "$README_FILE"

(
    cd build/archive
    sha256sum \
        "$(basename "$ARCHIVE_FILE")" \
        "$(basename "$README_FILE")" \
        > "$(basename "$CHECKSUM_FILE")"
)
OUTPUT_COMPLETE=1

log_cmd "Cleaning up container" \
    podman rm "$CONTAINER_NAME"
CONTAINER_CREATED=0

echo "=== Archive complete ===" | ts
echo "Archive saved to: $ARCHIVE_FILE" | ts
echo "Restoration guide: $README_FILE" | ts
echo "Checksums: $CHECKSUM_FILE" | ts
du -h "$ARCHIVE_FILE" | ts
