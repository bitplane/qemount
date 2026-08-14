FROM builder/compiler/illumos

COPY --chmod=0755 build.sh /build/build.sh
COPY qemount-init.c /build/qemount-init.c
COPY qemount-bootstrap.S /build/qemount-bootstrap.S

ENTRYPOINT ["/build/build.sh"]
