ARG BUILDER
FROM ${BUILDER}

COPY --chmod=755 build.sh build.py /build/
COPY plan9.ini plan9-arm64.ini qemount.rc qemount-mount.rc qemount-init.rc \
    qemount-fsprobe.c qemount.proto qemount-amd64.proto qemount-arm64.proto \
    qemount-build.rc /build/

ENTRYPOINT ["/build/build.sh"]
