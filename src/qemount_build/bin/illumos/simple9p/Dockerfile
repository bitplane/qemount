ARG BUILDER
FROM ${BUILDER}

COPY --chmod=0755 build.sh cc.sh link.sh /build/

ENTRYPOINT ["/build/build.sh"]
