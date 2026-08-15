FROM builder/compiler/rust

WORKDIR /build
COPY src/ /build/src/
COPY --chmod=755 build.sh /build/build.sh

ENTRYPOINT ["/build/build.sh"]
