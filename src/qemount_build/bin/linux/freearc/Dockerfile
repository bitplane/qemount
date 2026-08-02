FROM builder/compiler/freearc

COPY --chmod=755 build.sh /build.sh
COPY freearc-modern.patch /freearc-modern.patch
COPY compat /compat
ENTRYPOINT ["/build.sh"]
