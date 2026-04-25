#!/bin/bash
# Creates zig wrapper scripts for a given target
# Usage: zig-wrapper.sh <target> <output-dir>
#
# Provides a complete toolchain using zig as the backend, so no system
# compiler or binutils are needed. This avoids mismatches between system
# tools (e.g. GNU ar creating thin archives that zig's lld can't read).

TARGET=$1
OUTDIR=$2

# Per-target prefix dir holding our cross-built static deps and any
# generated import libraries. The cc/c++ wrappers rewrite
# -print-search-dirs to advertise this so meson's cc.find_library() can
# locate static libs we've placed there (e.g. libws2_32.a synthesised
# from zig's bundled mingw .def files).
PREFIX=/opt/$TARGET

# Find zig binary - pip package installs entry point as "python-zig"
ZIG=$(command -v zig 2>/dev/null || command -v python-zig 2>/dev/null) || {
    echo "error: zig not found (install via: pip install ziglang)" >&2
    exit 1
}

mkdir -p $OUTDIR

# Shared helper: recursively expand @file response files into plain args.
# Zig cc can't handle nested response files (NestedResponseFile error).
# Outputs one arg per line; caller uses unquoted $() to word-split.
cat > $OUTDIR/_expand << 'EXPAND'
#!/bin/sh
expand_file() {
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            @*) f="${line#@}"; [ -f "$f" ] && expand_file < "$f" || printf '%s\n' "$line" ;;
            "") ;;
            *) printf '%s\n' "$line" ;;
        esac
    done
}
for arg in "$@"; do
    case "$arg" in
        @*) f="${arg#@}"; [ -f "$f" ] && expand_file < "$f" || printf '%s\n' "$arg" ;;
        *) printf '%s\n' "$arg" ;;
    esac
done
EXPAND

cat > $OUTDIR/cc << EOF
#!/bin/sh
# Meson probes linker identity via -Wl,--version. zig's lld reports as
# "ld.zigcc" which meson doesn't recognise. Fake the lld banner so meson
# detects it correctly.
#
# Meson's cc.find_library() parses --print-search-dirs to discover lib
# dirs. Prepend our $PREFIX/lib so generated import libs and our
# cross-built static deps are findable without per-call dirs: kwargs.
# Match both -print-search-dirs (single dash) and --print-search-dirs
# (GCC long form, what meson uses), anywhere in the arg list — meson
# may pass additional check flags alongside.
for arg in "\$@"; do
    case "\$arg" in
        -Wl,--version)
            echo "LLD 20.1.2 (compatible with GNU linkers)"
            exit 0 ;;
        -print-search-dirs|--print-search-dirs)
            $ZIG cc -target $TARGET "\$@" \\
                | sed "s|^libraries: =|libraries: =$PREFIX/lib:|"
            exit 0 ;;
    esac
done
exec $ZIG cc -target $TARGET \$($OUTDIR/_expand "\$@")
EOF

cat > $OUTDIR/c++ << EOF
#!/bin/sh
for arg in "\$@"; do
    case "\$arg" in
        -Wl,--version)
            echo "LLD 20.1.2 (compatible with GNU linkers)"
            exit 0 ;;
        -print-search-dirs|--print-search-dirs)
            $ZIG c++ -target $TARGET "\$@" \\
                | sed "s|^libraries: =|libraries: =$PREFIX/lib:|"
            exit 0 ;;
    esac
done
exec $ZIG c++ -target $TARGET \$($OUTDIR/_expand "\$@")
EOF

# Meson passes 'T' flag to ar requesting thin archives, but zig's lld
# can't link them. Strip the T from the flags argument.
cat > $OUTDIR/ar << EOF
#!/bin/sh
flags=\$1; shift
flags=\$(echo "\$flags" | tr -d T)
exec $ZIG ar \$flags "\$@"
EOF

cat > $OUTDIR/ranlib << EOF
#!/bin/sh
exec $ZIG ranlib "\$@"
EOF

cat > $OUTDIR/ld << EOF
#!/bin/sh
exec $ZIG ld.lld "\$@"
EOF

cat > $OUTDIR/objcopy << EOF
#!/bin/sh
exec $ZIG objcopy "\$@"
EOF

# zig objcopy supports --strip-all
cat > $OUTDIR/strip << EOF
#!/bin/sh
exec $ZIG objcopy --strip-all "\$@" 2>/dev/null || true
EOF

# Windows resource compiler.
#
# Autotools packages call this as GNU windres, while zig rc exposes the MS
# rc/llvm-rc option shape. Translate the small option set used by configure
# builds so dependency packages do not need target-specific branches.
cat > $OUTDIR/windres << EOF
#!/bin/sh
out=
args=

append_arg() {
    quoted=\$(printf "%s\n" "\$1" | sed "s/'/'\\\\''/g")
    args="\$args '\$quoted'"
}

append_define() {
    # GNU windres is commonly invoked with C-shell-escaped string values such
    # as -DPACKAGE_VERSION_STRING=\"1.17\". llvm-rc/zig rc does not run that
    # through the same unescaping path, so pass the RC string literal directly.
    value=\$(printf "%s\n" "\$1" | sed 's/\\\"/"/g')
    append_arg "/D\$value"
}

while [ "\$#" -gt 0 ]; do
    case "\$1" in
        --output-format=coff|--output-format=COFF)
            shift
            ;;
        --output-format)
            shift
            [ "\$#" -gt 0 ] && shift
            ;;
        -O)
            shift
            [ "\$#" -gt 0 ] && shift
            ;;
        -o)
            shift
            out=\$1
            shift
            ;;
        -o*)
            out=\${1#-o}
            shift
            ;;
        --output=*)
            out=\${1#--output=}
            shift
            ;;
        -i|--input)
            shift
            [ "\$#" -gt 0 ] && append_arg "\$1"
            [ "\$#" -gt 0 ] && shift
            ;;
        -i*)
            append_arg "\${1#-i}"
            shift
            ;;
        --input=*)
            append_arg "\${1#--input=}"
            shift
            ;;
        -J|--input-format)
            shift
            [ "\$#" -gt 0 ] && shift
            ;;
        --input-format=*)
            shift
            ;;
        -l|--language)
            shift
            [ "\$#" -gt 0 ] && append_arg "/l\$1"
            [ "\$#" -gt 0 ] && shift
            ;;
        -l*)
            append_arg "/l\${1#-l}"
            shift
            ;;
        --language=*)
            append_arg "/l\${1#--language=}"
            shift
            ;;
        -I)
            shift
            [ "\$#" -gt 0 ] && append_arg "/I\$1"
            [ "\$#" -gt 0 ] && shift
            ;;
        -I*)
            append_arg "/I\${1#-I}"
            shift
            ;;
        --include-dir=*)
            append_arg "/I\${1#--include-dir=}"
            shift
            ;;
        -D)
            shift
            [ "\$#" -gt 0 ] && append_define "\$1"
            [ "\$#" -gt 0 ] && shift
            ;;
        -D*)
            append_define "\${1#-D}"
            shift
            ;;
        --define=*)
            append_define "\${1#--define=}"
            shift
            ;;
        -U)
            shift
            [ "\$#" -gt 0 ] && append_arg "/U\$1"
            [ "\$#" -gt 0 ] && shift
            ;;
        -U*)
            append_arg "/U\${1#-U}"
            shift
            ;;
        *)
            append_arg "\$1"
            shift
            ;;
    esac
done

if [ -n "\$out" ]; then
    quoted_out=\$(printf "%s\n" "\$out" | sed "s/'/'\\\\''/g")
    eval "exec $ZIG rc /fo '\$quoted_out' \$args"
fi

eval "exec $ZIG rc \$args"
EOF

chmod +x $OUTDIR/_expand $OUTDIR/cc $OUTDIR/c++ $OUTDIR/ar $OUTDIR/ranlib \
         $OUTDIR/ld $OUTDIR/objcopy $OUTDIR/strip $OUTDIR/windres

echo "Created zig wrappers for $TARGET in $OUTDIR"
