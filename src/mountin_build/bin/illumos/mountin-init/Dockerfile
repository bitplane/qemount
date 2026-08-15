ARG BUILDER
FROM ${BUILDER}

COPY --chmod=0755 build.sh /build/build.sh
COPY mountin-init.c /build/mountin-init.c
COPY mountin-bootstrap.S /build/mountin-bootstrap.S

ENTRYPOINT ["/build/build.sh"]
