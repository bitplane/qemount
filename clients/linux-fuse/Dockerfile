FROM ubuntu
RUN apt update && \
    apt upgrade --yes && \
    apt install --yes build-essential git meson cmake fuse \
                      pkg-config libfuse-dev
RUN mkdir /build && \
    git clone https://github.com/aperezdc/9pfuse.git /build/9pfuse

WORKDIR /build/9pfuse
RUN meson setup build && \
    meson compile -Cbuild

# /build/9pfuse/build
