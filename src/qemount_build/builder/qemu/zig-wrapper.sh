#!/bin/bash
# Creates zig wrapper scripts for a given target
# Usage: zig-wrapper.sh <target> <output-dir>

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
chmod +x $OUTDIR/cc

cat > $OUTDIR/c++ << EOF
#!/bin/sh
exec $ZIG c++ -target $TARGET "\$@"
EOF
chmod +x $OUTDIR/c++

cat > $OUTDIR/ar << EOF
#!/bin/sh
exec $ZIG ar "\$@"
EOF
chmod +x $OUTDIR/ar

cat > $OUTDIR/ranlib << EOF
#!/bin/sh
exec $ZIG ranlib "\$@"
EOF
chmod +x $OUTDIR/ranlib

# zig doesn't have strip, use true as no-op
cat > $OUTDIR/strip << EOF
#!/bin/sh
exit 0
EOF
chmod +x $OUTDIR/strip

echo "Created zig wrappers for $TARGET in $OUTDIR"
