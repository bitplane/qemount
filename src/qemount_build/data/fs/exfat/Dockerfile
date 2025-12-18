ARG ARCH
FROM localhost/qemount-common-qemu-builder-${ARCH}

RUN apk add --no-cache exfatprogs
COPY build.sh /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
