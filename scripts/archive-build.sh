#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR=/src
CAPSULE_DIR=/time-capsule

cd "$SOURCE_DIR"
make dev
"$SOURCE_DIR/.venv/bin/qemount-build" outputs --all-platforms \
    | xargs -r "$SOURCE_DIR/.venv/bin/qemount-build" build
"$SOURCE_DIR/.venv/bin/qemount-build" inventory

mkdir -p "$CAPSULE_DIR"

date -u +%Y-%m-%dT%H:%M:%SZ > "$CAPSULE_DIR/created-at.txt"
git rev-parse HEAD > "$CAPSULE_DIR/qemount-commit.txt"
git status --porcelain=v1 --untracked-files=all > "$CAPSULE_DIR/qemount-status.txt"
git bundle verify "$CAPSULE_DIR/qemount.bundle" \
    > "$CAPSULE_DIR/qemount-bundle.txt" 2>&1

uname -a > "$CAPSULE_DIR/uname.txt"
cp /etc/os-release "$CAPSULE_DIR/os-release"
dpkg-query -W -f='${binary:Package}\t${Version}\n' \
    | sort > "$CAPSULE_DIR/packages.tsv"
python3 --version > "$CAPSULE_DIR/python-version.txt" 2>&1

"$SOURCE_DIR/.venv/bin/qemount-build" outputs \
    --all-platforms --include-unavailable \
    > "$CAPSULE_DIR/qemount-outputs.txt"
find "$SOURCE_DIR/build" -type f -printf '%s\t%TY-%Tm-%TdT%TH:%TM:%TSZ\t%p\n' \
    | sort -k3 > "$CAPSULE_DIR/build-files.tsv"

podman version > "$CAPSULE_DIR/podman-version.txt"
podman info > "$CAPSULE_DIR/podman-info.txt"
podman images --no-trunc --digests \
    --format '{{.Repository}}:{{.Tag}}\t{{.Digest}}\t{{.ID}}\t{{.Size}}' \
    | sort > "$CAPSULE_DIR/podman-images.tsv"
podman ps -a --no-trunc \
    --format '{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}' \
    | sort > "$CAPSULE_DIR/podman-containers.tsv"

# No nested Podman commands may run after this point: the checksums describe
# the final, quiescent image store that will be captured by podman export.
sync
find "$SOURCE_DIR/build" /var/lib/containers -xdev -type f -print0 \
    | sort -z \
    | xargs -0 -r sha256sum \
    > "$CAPSULE_DIR/payload.sha256"

find "$CAPSULE_DIR" -maxdepth 1 -type f ! -name metadata.sha256 -print0 \
    | sort -z \
    | xargs -0 -r sha256sum \
    > "$CAPSULE_DIR/metadata.sha256"

sync
