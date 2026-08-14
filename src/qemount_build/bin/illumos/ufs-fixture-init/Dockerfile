FROM builder/compiler/illumos

COPY --chmod=0755 build.sh /build/build.sh
COPY ufs-fixture-init.c /build/ufs-fixture-init.c

ENTRYPOINT ["/build/build.sh"]
