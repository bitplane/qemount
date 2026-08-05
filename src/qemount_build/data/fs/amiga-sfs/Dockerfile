FROM builder/disk/guest

COPY --chmod=755 build.sh /build/build.sh
COPY grub.cfg /build/grub.cfg
COPY User-Startup /build/User-Startup

ENTRYPOINT ["/build/build.sh"]
