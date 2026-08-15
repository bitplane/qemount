#!/bin/bash
set -euo pipefail

source_root=/source/usr/src
onbld=$source_root/tools/proto/root_i386-nd/opt/onbld
sysroot=/opt/illumos/sysroot

compile=false
for argument in "$@"; do
    case "$argument" in
        -c|-E|-S)
            compile=true
            ;;
    esac
done

if ! $compile; then
    exec x86_64-illumos-ld "$@"
fi

arguments=()
for argument in "$@"; do
    case "$argument" in
        -O*|-g*|-f*|-W*|-MMD|-MP)
            arguments+=("-_gcc=$argument")
            ;;
        *)
            arguments+=("$argument")
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
    -xc99=%all \
    -I"$sysroot/usr/include" \
    "${arguments[@]}"
