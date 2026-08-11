ARG BUILDER
FROM ${BUILDER}

COPY Makefile list /work/qemount-crunch/
COPY mount-filecore-node.patch /work/

RUN set -eu; \
    mkdir -p /usr/src; \
    tar -xzf /host/build/sources/netbsd-10.0-src.tgz -C /; \
    tar -xzf /host/build/sources/netbsd-10.0-syssrc.tgz -C /; \
    tar -xzf /host/build/sources/netbsd-10.0-sharesrc.tgz -C /; \
    patch -d /usr/src -p1 < /work/mount-filecore-node.patch; \
    NBARCH=$(cat /tmp/nbarch); \
    NBMAKE="/usr/tools/bin/nbmake-$NBARCH"; \
    "$NBMAKE" -C /work/qemount-crunch qemount-rescue; \
    "$NBMAKE" -C /usr/src/etc MAKEDEV; \
    mkdir -p /opt/qemount; \
    cp /work/qemount-crunch/qemount-rescue /opt/qemount/; \
    { \
        echo '. type=dir optional'; \
        echo './dev type=dir optional'; \
        cd /work; \
        /bin/sh /usr/src/etc/MAKEDEV -s \
            std ttyVI \
            ld0 ld1 ld2 ld3 ld4 ld5 ld6 ld7 ld8 ld9 ld10 ld11 ld12 ld13 ld14 ld15 \
            dk0 dk1 dk2 dk3 dk4 dk5 dk6 dk7 dk8 dk9 dk10 dk11 dk12 dk13 dk14 dk15 \
            dk16 dk17 dk18 dk19 dk20 dk21 dk22 dk23 dk24 dk25 dk26 dk27 dk28 dk29 \
            dk30 dk31 dk32 dk33 dk34 dk35 dk36 dk37 dk38 dk39 dk40 dk41 dk42 dk43 \
            dk44 dk45 dk46 dk47 dk48 dk49 dk50 dk51 dk52 dk53 dk54 dk55 dk56 dk57 \
            dk58 dk59 dk60 dk61 dk62 dk63 \
        | sed -n '2,$s#^\./#./dev/#p'; \
    } > /opt/qemount/devices.mtree; \
    rm -rf /usr/src /work/qemount-crunch

COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
