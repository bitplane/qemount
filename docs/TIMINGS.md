# Linux optimization stuff

# before:

2.6:  [    3.330067] mount used greatest stack depth: 5784 bytes left
6.17: [    6.835608] mkdir (75) used greatest stack depth: 13472 bytes left

# 1. remove strace and socat

2.6:  [    3.383105] mount used greatest stack depth: 5784 bytes left
6.17: [    6.761053] mkdir (75) used greatest stack depth: 13472 bytes left

Negligible - reverted changes

# 2. have initramfs decompressed
2.6:  [    2.801071] mount used greatest stack depth: 5784 bytes left
6.17: boot failure

# 3. use -1 on gzip for initramfs
2.6:  [    3.225046] mount used greatest stack depth: 5784 bytes left
6.17: [    6.643178] mkdir (75) used greatest stack depth: 13472 bytes left

# 4. rebuild 6.17 kernel to work uncompressed
This didn't work. It ran out of RAM?

# 5. increase RAM after initramfs unpacked (256mb)
2.6:  [    2.542068] mount used greatest stack depth: 5784 bytes left
6.17: [    5.905531] mkdir (74) used greatest stack depth: 13472 bytes left

# 6. remove components we don't care about

2.6:  [    2.282071] mount used greatest stack depth: 5784 bytes left
6.17: [    5.433873] mkdir (63) used greatest stack depth: 13472 bytes left

# 7. more aggressive removals
```
./build/common/run/qemu-linux/run-linux.sh x86_64 build/guests/linux/2.6/x86_64/kernel build/guests/linux/initramfs/x86_64/initramfs.cpio -i build/tests/data/images/basic.ext2 | tee 2.timing.log

grep -E 'after [0-9]+ usecs' /home/gaz/src/qemount/2.timing.log | sed 's/.*after \([0-9]*\) usecs.*/\1/' | paste -d' ' - <(grep -E 'after [0-9]+ usecs' /home/gaz/src/qemount/2.timing.log) | sort -rn | head -30
```
etc

2.6:  [    1.774308] Switching to clocksource tsc
6.17: [    2.759441] mkdir (60) used greatest stack depth: 13488 bytes left






future:

* drop initramfs approach entirely - boot into an ext2 image
