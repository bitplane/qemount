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

cat > $OUTDIR/cc << EOF
#!/bin/sh
exec $ZIG cc -target $TARGET "\$@"
EOF

cat > $OUTDIR/c++ << EOF
#!/bin/sh
exec $ZIG c++ -target $TARGET "\$@"
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

chmod +x $OUTDIR/cc $OUTDIR/c++ $OUTDIR/ar $OUTDIR/ranlib \
         $OUTDIR/ld $OUTDIR/objcopy $OUTDIR/strip

echo "Created zig wrappers for $TARGET in $OUTDIR"
