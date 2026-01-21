FROM builder/compiler/rust

WORKDIR /build
COPY Cargo.toml /build/
COPY src /build/src/
COPY include /build/include/
COPY --chmod=755 build.sh /build/

ENTRYPOINT ["/build/build.sh"]
