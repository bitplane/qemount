FROM builder/disk/debian

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates \
        python3 python3-pip python3-dev \
        wine wine32 && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages acefile

# Commandline ACE 2.6. The .exe is itself an ACE self-extracting archive
# containing ACE.EXE (DOS), ACE32.EXE (Win32 console), and ACE2.EXE (OS/2).
# We use ACE32.EXE under Wine - the DOS version is intolerably slow in DOSBox.
# Mirror: https://web.archive.org/web/20060207140655if_/http://www.winace.com/files/ace26.exe
RUN curl -sL "https://www.sac.sk/download/pack/ace26.exe" \
        -o /tmp/ace26.exe && \
    mkdir -p /usr/local/share/ace && \
    cd /usr/local/share/ace && \
    python3 -c "import acefile; \
        f = acefile.open('/tmp/ace26.exe'); \
        [f.extract(m) for m in f.getmembers() if m.filename.upper() == 'ACE32.EXE']" && \
    rm /tmp/ace26.exe

COPY --chmod=755 build.sh /build/build.sh
