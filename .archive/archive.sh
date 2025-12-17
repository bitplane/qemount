#!/bin/bash
set -euo pipefail

DATE=$(date +%Y-%m-%d_%H-%M)
BUILDER_IMAGE="qemount-builder"
CONTAINER_NAME="qemount-build-$$"

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

log_cmd "Building archive environment" \
    podman build -f .archive/Dockerfile -t "$BUILDER_IMAGE" .

log_cmd "Running build" \
    podman run --privileged --name "$CONTAINER_NAME" "$BUILDER_IMAGE"

mkdir -p build/archive
ARCHIVE_FILE="build/archive/${DATE}_qemount.tar.xz"

# Use export instead of save - exports container filesystem directly
# without the layer overhead that makes podman save pathologically slow
log_cmd "Exporting archive" \
    sh -c "podman export '$CONTAINER_NAME' | xz -9 > '$ARCHIVE_FILE'"

log_cmd "Cleaning up container" \
    podman rm "$CONTAINER_NAME"

echo "=== Archive complete ===" | ts
echo "Archive saved to: $ARCHIVE_FILE" | ts
ls -lh "$ARCHIVE_FILE" | ts
