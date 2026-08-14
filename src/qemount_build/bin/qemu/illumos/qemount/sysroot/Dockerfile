FROM builder/compiler/illumos

COPY --chmod=0755 build.sh /build/build.sh
COPY plockstat-stubs.c /build/plockstat-stubs.c

ENTRYPOINT ["/build/build.sh"]
