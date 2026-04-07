#!/bin/bash
# Creates zig wrapper scripts for a given target
# Usage: zig-wrapper.sh <target> <output-dir>

TARGET=$1
OUTDIR=$2

mkdir -p $OUTDIR

cat > $OUTDIR/cc << EOF
#!/bin/sh
exec zig cc -target $TARGET "\$@"
EOF
chmod +x $OUTDIR/cc

cat > $OUTDIR/c++ << EOF
#!/bin/sh
exec zig c++ -target $TARGET "\$@"
EOF
chmod +x $OUTDIR/c++

cat > $OUTDIR/ar << EOF
#!/bin/sh
exec zig ar "\$@"
EOF
chmod +x $OUTDIR/ar

cat > $OUTDIR/ranlib << EOF
#!/bin/sh
exec zig ranlib "\$@"
EOF
chmod +x $OUTDIR/ranlib

# zig doesn't have strip, use true as no-op
cat > $OUTDIR/strip << EOF
#!/bin/sh
exit 0
EOF
chmod +x $OUTDIR/strip

echo "Created zig wrappers for $TARGET in $OUTDIR"
