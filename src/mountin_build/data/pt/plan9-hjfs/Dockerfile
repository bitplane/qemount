FROM builder/disk/9front

COPY --chmod=755 build.sh fixture.rc verify.py /build/

ENTRYPOINT ["/build/build.sh"]

