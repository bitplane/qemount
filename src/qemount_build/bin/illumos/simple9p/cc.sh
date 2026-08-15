#!/bin/bash
set -euo pipefail

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
sysroot=/opt/illumos/sysroot

args=()
for arg in "$@"; do
    case "$arg" in
        -O*|-g*|-f*|-W*|-MMD|-MP)
            args+=("-_gcc=$arg")
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done

exec "$onbld/bin/i386/cw" \
    --tag target \
    --linker "$onbld/bin/amd64/ld" \
    --primary gcc12,/usr/bin/gcc,gnu \
    -- \
    -m64 \
    -_gcc=-fno-stack-protector \
    -_gcc=-nostdinc \
    -_gcc=-include \
    -_gcc=sys/time.h \
    -xc99=%all \
    -I"$sysroot/usr/include" \
    "${args[@]}"
