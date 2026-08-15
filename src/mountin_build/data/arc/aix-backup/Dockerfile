FROM builder/disk/debian

COPY mkbff.c /build/mkbff.c
RUN gcc -O2 -o /usr/local/bin/mkbff /build/mkbff.c

COPY --chmod=755 build.sh /build/build.sh
