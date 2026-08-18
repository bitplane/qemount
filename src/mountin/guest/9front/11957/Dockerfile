ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

COPY --chmod=755 build.sh build.py /build/
COPY plan9.ini plan9-arm64.ini mountin.rc mountin-mount.rc mountin-init.rc \
    mountin-fsprobe.c mountin.proto mountin-amd64.proto mountin-arm64.proto \
    mountin-build.rc /build/

ENTRYPOINT ["/build/build.sh"]
