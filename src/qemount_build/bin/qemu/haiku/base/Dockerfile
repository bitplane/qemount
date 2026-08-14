ARG BUILDER
FROM ${BUILDER}

ARG OUTPUT_ARCH
ARG JOBS=1
ARG HAIKU_IMAGE_SIZE
ARG HAIKU_REVISION
ENV OUTPUT_ARCH=${OUTPUT_ARCH}
ENV JOBS=${JOBS}
ENV HAIKU_IMAGE_SIZE=${HAIKU_IMAGE_SIZE}
ENV HAIKU_REVISION=${HAIKU_REVISION}

WORKDIR /src/haiku/generated
COPY qemount-profile.patch /tmp/qemount-profile.patch
RUN patch -d /src/haiku -p1 < /tmp/qemount-profile.patch
COPY qemount-pci-names.patch /tmp/qemount-pci-names.patch
RUN patch -d /src/haiku -p1 < /tmp/qemount-pci-names.patch
COPY profile/definition /src/haiku/build/qemount/definition
COPY profile/package /src/haiku/build/jam/packages/HaikuQemount
COPY profile/package-info /src/haiku/src/data/package_infos/generic/haiku_qemount
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
