FROM builder/compiler/rust

WORKDIR /build
COPY src/ /build/src/
COPY build.sh /build/
RUN chmod +x /build/build.sh

ENTRYPOINT ["/build/build.sh"]
