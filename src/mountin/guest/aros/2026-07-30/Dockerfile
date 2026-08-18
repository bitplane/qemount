ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build/build.sh
COPY mmake-prepare-targets.txt mmake-targets.txt mmake-outputs.txt system-files.txt grub.cfg Startup-Sequence /build/
ENTRYPOINT ["/build/build.sh"]
