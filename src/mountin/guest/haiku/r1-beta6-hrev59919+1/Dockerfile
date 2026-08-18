ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

ARG MOUNTIN_TARGET_ARCH
ARG MOUNTIN_BUILD_JOBS=1
ARG MOUNTIN_HAIKU_IMAGE_SIZE
ARG MOUNTIN_HAIKU_REVISION
ENV MOUNTIN_TARGET_ARCH=${MOUNTIN_TARGET_ARCH}
ENV MOUNTIN_BUILD_JOBS=${MOUNTIN_BUILD_JOBS}
ENV MOUNTIN_HAIKU_IMAGE_SIZE=${MOUNTIN_HAIKU_IMAGE_SIZE}
ENV MOUNTIN_HAIKU_REVISION=${MOUNTIN_HAIKU_REVISION}

WORKDIR /src/haiku/generated
COPY mountin-profile.patch /tmp/mountin-profile.patch
RUN patch -d /src/haiku -p1 < /tmp/mountin-profile.patch
COPY mountin-pci-names.patch /tmp/mountin-pci-names.patch
RUN patch -d /src/haiku -p1 < /tmp/mountin-pci-names.patch
COPY profile/definition /src/haiku/build/mountin/definition
COPY profile/package /src/haiku/build/jam/packages/HaikuMountin
COPY profile/package-info /src/haiku/src/data/package_infos/generic/haiku_mountin
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
