ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

RUN apk add --no-cache exfatprogs tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
