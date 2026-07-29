#!/bin/sh
set -eu

output="/host/build/$1"
mkdir -p "$(dirname "$output")"

ofs=/host/build/data/fs/basic.amiga-ofs
ffs=/host/build/data/fs/basic.amiga-ffs
pfs=/host/build/data/fs/basic.amiga-pfs
sfs=/host/build/data/fs/basic.amiga-sfs

# All source fixtures are aligned to 16 512-byte sectors. Using the same
# cylinder size here preserves each filesystem byte-for-byte when imported.
cylinder_blocks=16
cylinder_bytes=$((cylinder_blocks * 512))

cylinders()
{
    size=$(stat -c %s "$1")
    if [ $((size % cylinder_bytes)) -ne 0 ]; then
        echo "Fixture is not aligned to $cylinder_bytes bytes: $1" >&2
        exit 1
    fi
    echo $((size / cylinder_bytes))
}

ofs_cyls=$(cylinders "$ofs")
ffs_cyls=$(cylinders "$ffs")
pfs_cyls=$(cylinders "$pfs")
sfs_cyls=$(cylinders "$sfs")

# Cylinder zero is reserved for the RDB.
ofs_start=1
ofs_end=$((ofs_start + ofs_cyls - 1))
ffs_start=$((ofs_end + 1))
ffs_end=$((ffs_start + ffs_cyls - 1))
pfs_start=$((ffs_end + 1))
pfs_end=$((pfs_start + pfs_cyls - 1))
sfs_start=$((pfs_end + 1))
sfs_end=$((sfs_start + sfs_cyls - 1))
total_cyls=$((sfs_end + 11))

rm -f "$output"
rdbtool -f "$output" create chs="$total_cyls,1,$cylinder_blocks" \
    + init \
    + add start="$ofs_start" end="$ofs_end" dostype=DOS0 \
    + add start="$ffs_start" end="$ffs_end" dostype=DOS1 \
    + add start="$pfs_start" end="$pfs_end" dostype=PFS3 \
    + add start="$sfs_start" end="$sfs_end" dostype=SFS0 \
    + import 0 "$ofs" \
    + import 1 "$ffs" \
    + import 2 "$pfs" \
    + import 3 "$sfs"

# Verify that RDB construction preserved every source filesystem byte-for-byte.
for partition in 0 1 2 3; do
    exported="/tmp/rdb-partition-$partition"
    rdbtool -f "$output" export "$partition" "$exported"
    case "$partition" in
        0) source=$ofs ;;
        1) source=$ffs ;;
        2) source=$pfs ;;
        3) source=$sfs ;;
    esac
    cmp "$source" "$exported"
done

echo "Built: $1"
