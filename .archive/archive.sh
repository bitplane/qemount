#!/bin/bash
set -euo pipefail

DATE=$(date +%Y%m%d)
BUILDER_IMAGE="qemount-builder"
ARCHIVE_IMAGE="qemount-archive"
CONTAINER_NAME="qemount-build-$$"
OUTPUT_FILE="qemount-archive-${DATE}.tar.xz"

echo "=== Building archive environment ==="
podman build -f .archive/Dockerfile -t "$BUILDER_IMAGE" .

echo "=== Running build (this may take a while) ==="
podman run --privileged --name "$CONTAINER_NAME" "$BUILDER_IMAGE"

echo "=== Committing result ==="
podman commit "$CONTAINER_NAME" "$ARCHIVE_IMAGE"

echo "=== Saving and compressing ==="
podman save "$ARCHIVE_IMAGE" | xz -9e -T0 -v > "$OUTPUT_FILE"

echo "=== Cleanup ==="
podman rm "$CONTAINER_NAME"

echo "=== Done ==="
echo "Archive created: $OUTPUT_FILE"
echo "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""
echo "To restore and use:"
echo "  xzcat $OUTPUT_FILE | podman load"
echo "  podman run -it $ARCHIVE_IMAGE /bin/bash"
