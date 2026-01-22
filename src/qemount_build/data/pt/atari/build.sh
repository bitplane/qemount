#!/bin/sh
set -e

# Build Atari AHDI partition table with 2 partitions
# Partition 0: basic.fat16 (16MB) as BGM
# Partition 1: basic.fat12 (8MB) as GEM

OUTPUT="/host/build/$1"
FAT16="/host/build/data/fs/basic.fat16"
FAT12="/host/build/data/fs/basic.fat12"

mkdir -p "$(dirname "$OUTPUT")"

# Get sizes in bytes and sectors (512 bytes per sector)
fat16_bytes=$(stat -c%s "$FAT16")
fat12_bytes=$(stat -c%s "$FAT12")
fat16_sectors=$((fat16_bytes / 512))
fat12_sectors=$((fat12_bytes / 512))

# Partition layout:
# Sector 0: rootsector
# Sector 1: start of partition 0 (fat16)
# Sector 1+fat16_sectors: start of partition 1 (fat12)
part0_start=1
part0_size=$fat16_sectors
part1_start=$((part0_start + part0_size))
part1_size=$fat12_sectors
total_sectors=$((part1_start + part1_size))

# Create 512-byte rootsector
rootsector=$(mktemp)
dd if=/dev/zero of="$rootsector" bs=512 count=1 2>/dev/null

# Helper: write big-endian 32-bit value at offset
write_be32() {
    local file=$1 offset=$2 value=$3
    printf "\\x$(printf '%02x' $(((value >> 24) & 0xff)))" | dd of="$file" bs=1 seek="$offset" count=1 conv=notrunc 2>/dev/null
    printf "\\x$(printf '%02x' $(((value >> 16) & 0xff)))" | dd of="$file" bs=1 seek="$((offset + 1))" count=1 conv=notrunc 2>/dev/null
    printf "\\x$(printf '%02x' $(((value >> 8) & 0xff)))" | dd of="$file" bs=1 seek="$((offset + 2))" count=1 conv=notrunc 2>/dev/null
    printf "\\x$(printf '%02x' $((value & 0xff)))" | dd of="$file" bs=1 seek="$((offset + 3))" count=1 conv=notrunc 2>/dev/null
}

# Write hd_siz at 0x1c2 (total disk size in sectors)
write_be32 "$rootsector" 450 $total_sectors

# Partition 0 at 0x1c6 (12 bytes): flag + id[3] + start[4] + size[4]
# Flag 0x01 = active, ID = "BGM" (>16MB partition)
printf '\x01BGM' | dd of="$rootsector" bs=1 seek=454 count=4 conv=notrunc 2>/dev/null
write_be32 "$rootsector" 458 $part0_start
write_be32 "$rootsector" 462 $part0_size

# Partition 1 at 0x1d2 (12 bytes): flag + id[3] + start[4] + size[4]
# Flag 0x01 = active, ID = "GEM" (<16MB partition)
printf '\x01GEM' | dd of="$rootsector" bs=1 seek=466 count=4 conv=notrunc 2>/dev/null
write_be32 "$rootsector" 470 $part1_start
write_be32 "$rootsector" 474 $part1_size

# Concatenate: rootsector + fat16 + fat12
cat "$rootsector" "$FAT16" "$FAT12" > "$OUTPUT"

rm -f "$rootsector"
echo "Built: $OUTPUT ($(stat -c%s "$OUTPUT") bytes, $total_sectors sectors)"
