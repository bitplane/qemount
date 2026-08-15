FROM builder/compiler/rust

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
