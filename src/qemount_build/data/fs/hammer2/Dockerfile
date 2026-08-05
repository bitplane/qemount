FROM builder/disk/guest

COPY --chmod=755 fixture.rc /build/fixture.rc
COPY --chmod=755 build.sh /build/build.sh

ENTRYPOINT ["/build/build.sh"]
