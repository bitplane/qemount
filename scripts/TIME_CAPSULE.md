# qemount build time capsule

This archive is an exported Linux container filesystem containing:

- the complete qemount Git repository and history at the recorded revision;
- every downloaded source archive and generated build output;
- the qemount build cache and logs;
- a private Podman image store containing the complete builder images,
  toolchains, guest builders, and test-data builders used by the build;
- inventories and SHA-256 checksums under `/time-capsule`.

No network access should be needed to inspect the completed build or run the
captured Podman images.

## Verify the downloaded files

Place the `.tar.xz`, `.README.md`, and `.sha256` files in one directory:

```sh
sha256sum -c *_qemount.sha256
```

## Import the capsule

Importing converts the exported root filesystem back into a local container
image. Choose any local image name:

```sh
xz -dc *_qemount.tar.xz | podman import - qemount-time-capsule:archived
```

The export format does not retain the original container command or working
directory, so specify both when opening it:

```sh
podman run --rm -it --privileged \
  --workdir /src \
  qemount-time-capsule:archived \
  /bin/bash
```

The outer container must be privileged so that its captured, nested Podman
installation can use the image store at `/var/lib/containers`.

## Inspect and verify the contents

Inside the capsule:

```sh
cat /time-capsule/qemount-commit.txt
cat /time-capsule/podman-images.tsv
cd /
sha256sum -c /time-capsule/metadata.sha256
sha256sum -c /time-capsule/payload.sha256
```

The qemount checkout is at `/src`, with build outputs under `/src/build`.
The complete repository can also be reconstructed independently from its Git
bundle:

```sh
git clone /time-capsule/qemount.bundle /tmp/qemount
```

Captured builder images can be inspected or run with the nested Podman:

```sh
podman images
podman inspect localhost/builder/compiler/rust:latest
```
