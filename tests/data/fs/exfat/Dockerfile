ARG ARCH
FROM qemount-common-compiler-${ARCH}
ARG ARCH

# For Alpine, we can only create empty exFAT filesystems
RUN apk add --no-cache exfatprogs tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]