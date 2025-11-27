ARG ARCH
FROM localhost/qemount-common-compiler-haiku-${ARCH}
ARG ARCH

WORKDIR /src/haiku/generated
RUN jam -q '<build>bfs_shell'

RUN dnf install -y tar && dnf clean all
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
