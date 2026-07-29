ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY grub.cfg /grub.cfg
COPY grub-modules.txt /grub-modules.txt
COPY runtime-files.txt /runtime-files.txt
COPY Startup-Sequence /Startup-Sequence
ENTRYPOINT ["/build.sh"]
