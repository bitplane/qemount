FROM builder/disk/guest

COPY --chmod=755 build.sh /build/build.sh
COPY root /build/root
ENTRYPOINT ["/build/build.sh"]
