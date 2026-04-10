/*
 * Minimal Tux3 filesystem image creator
 * Based on Daniel Phillips' tux3 source (github.com/danielbot/tux3).
 *
 * Creates a minimal Tux3 filesystem image with a valid superblock for
 * detection testing. Tux3 is a complex B-tree filesystem; this creates
 * only the superblock structure, not a fully functional filesystem.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <time.h>

#define SB_LOC          0x1000  /* superblock offset */
#define BLOCK_BITS      12      /* log2(4096) */
#define BLOCK_SIZE      (1 << BLOCK_BITS)

/* Big-endian writers */
static void put_be16(uint8_t *p, uint16_t v) { p[0] = v >> 8; p[1] = v; }
static void put_be32(uint8_t *p, uint32_t v) { p[0] = v >> 24; p[1] = v >> 16; p[2] = v >> 8; p[3] = v; }
static void put_be64(uint8_t *p, uint64_t v) {
    put_be32(p, v >> 32);
    put_be32(p + 4, v);
}

static void die(const char *msg)
{
    fprintf(stderr, "mkfs.tux3: %s\n", msg);
    exit(1);
}

int main(int argc, char **argv)
{
    int size_mb = 10;

    int opt;
    while ((opt = getopt(argc, argv, "s:")) != -1) {
        switch (opt) {
        case 's': size_mb = atoi(optarg); break;
        default:
            fprintf(stderr, "Usage: %s [-s size_mb] <output>\n", argv[0]);
            return 1;
        }
    }
    if (optind >= argc) {
        fprintf(stderr, "Usage: %s [-s size_mb] <output>\n", argv[0]);
        return 1;
    }

    char *filename = argv[optind];
    uint64_t image_size = (uint64_t)size_mb * 1024 * 1024;
    uint64_t vol_blocks = image_size >> BLOCK_BITS;

    if (vol_blocks < 16)
        die("volume too small");

    /* Create image file */
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) { perror("open"); return 1; }
    if (ftruncate(fd, image_size) < 0) { perror("ftruncate"); return 1; }

    /* Build superblock (disksuper structure) */
    uint8_t sb[BLOCK_SIZE];
    memset(sb, 0, sizeof(sb));

    /* Magic: "tux3" + date bytes 0x20 0x12 0x12 0x20 */
    static const uint8_t magic[8] = { 't', 'u', 'x', '3', 0x20, 0x12, 0x12, 0x20 };
    memcpy(sb, magic, 8);

    /* Birthdate (seconds since epoch, big-endian) */
    put_be64(sb + 8, (uint64_t)time(NULL));

    /* Flags */
    put_be64(sb + 16, 0);

    /* Block bits */
    put_be16(sb + 24, BLOCK_BITS);

    /* Padding (unused[3]) */
    /* Already zeroed */

    /* Volume blocks */
    put_be64(sb + 32, vol_blocks);

    /* iroot, oroot, usedinodes, nextalloc, atomdictsize, freeatom, atomgen */
    /* Leave as zero — this is a minimal image for detection */

    /* Write superblock at SB_LOC */
    if (lseek(fd, SB_LOC, SEEK_SET) != SB_LOC) { perror("lseek"); return 1; }
    if (write(fd, sb, BLOCK_SIZE) != BLOCK_SIZE) { perror("write"); return 1; }

    close(fd);

    printf("Created tux3 image: %s (%dMB, %lu blocks, blocksize %d)\n",
           filename, size_mb, (unsigned long)vol_blocks, BLOCK_SIZE);

    return 0;
}
