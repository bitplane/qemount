ARG BUILDER
FROM ${BUILDER}

COPY --chmod=755 build.sh build.py /build/
COPY plan9.ini qemount.rc qemount-init.rc /build/

ENTRYPOINT ["/build/build.sh"]
