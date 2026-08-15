FROM builder/disk/9front

COPY --chmod=755 build.sh fixture.rc /build/

ENTRYPOINT ["/build/build.sh"]
