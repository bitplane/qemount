#!/bin/sh
set -eu

VERSION=0.51
SOURCE_DIR=/work/FreeArc-$VERSION-sources
OBJECT_DIR=$MOUNTIN_CACHE_DIR/objects
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-linux-gnu

rm -rf "$SOURCE_DIR"
mkdir -p /work "$OBJECT_DIR/ghc" "$OUTPUT_DIR"
tar -xjf "/host/build/sources/FreeArc-$VERSION-sources.tar.bz2" -C /work
cd "$SOURCE_DIR"
patch -p1 < /freearc-modern.patch
# ArcCreate.hs uses a legacy source encoding, so keep this syntax-only rewrite
# out of the UTF-8 compatibility patch.
sed -i 's/command @ Command/command@Command/' ArcCreate.hs

case "$(getconf LONG_BIT)" in
    64) address_define=-DFREEARC_64BIT ;;
    32) address_define= ;;
    *) echo "Unsupported native word size" >&2; exit 1 ;;
esac

case "$(printf '\1\0' | od -An -t x2 | tr -d ' ')" in
    0001) endian_define=-DFREEARC_INTEL_BYTE_ORDER ;;
    0100) endian_define=-DFREEARC_MOTOROLA_BYTE_ORDER ;;
    *) echo "Unable to determine native byte order" >&2; exit 1 ;;
esac

defines="-DFREEARC_UNIX -DFREEARC_NO_LUA $endian_define $address_define"
cat > common.mak <<EOF
DEFINES = $defines
TEMPDIR = $OBJECT_DIR
GCC = g++
EOF

build_objects()
{
    make -C "$1" OPT_FLAGS='-O2 -fomit-frame-pointer -fstrict-aliasing'
}

build_objects Compression
for component in External LZP REP Delta MM Tornado Dict PPMD GRZip LZMA _Encryption; do
    build_objects "Compression/$component"
done
build_objects .

c_modules="
    $OBJECT_DIR/Environment.o
    $OBJECT_DIR/URL.o
    $OBJECT_DIR/Common.o
    $OBJECT_DIR/CompressionLibrary.o
    $OBJECT_DIR/C_PPMD.o
    $OBJECT_DIR/C_LZP.o
    $OBJECT_DIR/C_LZMA.o
    $OBJECT_DIR/C_BCJ.o
    $OBJECT_DIR/C_GRZip.o
    $OBJECT_DIR/C_Dict.o
    $OBJECT_DIR/C_REP.o
    $OBJECT_DIR/C_MM.o
    $OBJECT_DIR/C_TTA.o
    $OBJECT_DIR/C_Tornado.o
    $OBJECT_DIR/C_Delta.o
    $OBJECT_DIR/C_External.o
    $OBJECT_DIR/C_Encryption.o
"

# shellcheck disable=SC2086
ghc --make -O2 Arc.hs \
    -iCompression \
    -i/compat \
    -threaded \
    -XUndecidableInstances \
    -XOverlappingInstances \
    -XNoMonomorphismRestriction \
    -XBangPatterns \
    -XMagicHash \
    -XUnboxedTuples \
    -XUnliftedFFITypes \
    -XScopedTypeVariables \
    -XMultiParamTypeClasses \
    -XFunctionalDependencies \
    -XFlexibleInstances \
    -XFlexibleContexts \
    -XBlockArguments \
    -XParallelListComp \
    -XRecursiveDo \
    -DFREEARC_PACKED_STRINGS \
    $defines \
    -optc-DFREEARC_UNIX \
    -optc"$endian_define" \
    $c_modules \
    -lstdc++ -lncurses -lcurl \
    -odir "$OBJECT_DIR/ghc" \
    -hidir "$OBJECT_DIR/ghc" \
    -o "$OUTPUT_DIR/freearc" \
    +RTS -A2m
