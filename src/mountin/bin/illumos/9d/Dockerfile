ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

COPY --chmod=0755 build.sh /build/

ENTRYPOINT ["/build/build.sh"]
