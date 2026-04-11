FROM builder/disk/debian

# 32-bit compat libs for the i386 FreeArc binary
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates bzip2 \
        libc6:i386 \
        libstdc++6:i386 \
        libncurses5:i386 \
        libcurl4:i386 \
        libgmp10:i386 && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/lib/i386-linux-gnu/libgmp.so.10 /usr/lib/i386-linux-gnu/libgmp.so.3

# Download FreeArc 0.51 i386 binary (last release with Linux support)
RUN curl -sL "https://sourceforge.net/projects/freearc/files/FreeArc/FreeArc%200.51/FreeArc-0.51-linux-i386.tar.bz2/download" \
        -o /tmp/freearc.tar.bz2 && \
    tar xjf /tmp/freearc.tar.bz2 -C /tmp && \
    cp /tmp/FreeArc-0.51-linux-i386/bin/arc /usr/local/bin/freearc && \
    chmod +x /usr/local/bin/freearc && \
    rm -rf /tmp/freearc.tar.bz2 /tmp/FreeArc-0.51-linux-i386

# Archive the source code inside the container for future researchers.
# We use the prebuilt i386 binary above, but the Haskell+C++ source is
# preserved here so it can be rebuilt with a future toolchain.
RUN curl -sL "https://sourceforge.net/projects/freearc/files/FreeArc/FreeArc%200.51/FreeArc-0.51-sources.tar.bz2/download" \
        -o /opt/FreeArc-0.51-sources.tar.bz2

COPY --chmod=755 build.sh /build/build.sh
