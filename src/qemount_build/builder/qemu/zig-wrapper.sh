#!/bin/bash
# Creates zig wrapper scripts for a given target
# Usage: zig-wrapper.sh <target> <output-dir>
#
# Provides a complete toolchain using zig as the backend, so no system
# compiler or binutils are needed. This avoids mismatches between system
# tools (e.g. GNU ar creating thin archives that zig's lld can't read).

TARGET=$1
OUTDIR=$2

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
for arg in "\$@"; do
    case "\$arg" in -Wl,--version)
        echo "LLD 20.1.2 (compatible with GNU linkers)"
        exit 0 ;;
    esac
done
exec $ZIG cc -target $TARGET \$($OUTDIR/_expand "\$@")
EOF

cat > $OUTDIR/c++ << EOF
#!/bin/sh
for arg in "\$@"; do
    case "\$arg" in -Wl,--version)
        echo "LLD 20.1.2 (compatible with GNU linkers)"
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

# Windows resource compiler (zig rc wraps llvm-rc)
cat > $OUTDIR/windres << EOF
#!/bin/sh
exec $ZIG rc "\$@"
EOF

chmod +x $OUTDIR/_expand $OUTDIR/cc $OUTDIR/c++ $OUTDIR/ar $OUTDIR/ranlib \
         $OUTDIR/ld $OUTDIR/objcopy $OUTDIR/strip $OUTDIR/windres

echo "Created zig wrappers for $TARGET in $OUTDIR"
