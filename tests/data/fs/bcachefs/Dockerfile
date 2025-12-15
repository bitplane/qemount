ARG ARCH
FROM localhost/qemount-common-qemu-builder-${ARCH}
COPY build.sh /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
