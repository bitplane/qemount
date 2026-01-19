/*
 * detect - Simple format detection CLI tool
 *
 * Links against libqemount.a via C to validate the C ABI.
 */

#include <stdio.h>
#include <stdlib.h>
#include "qemount.h"

#define BUFFER_SIZE 131072  /* 128KB - needed for btrfs magic at 0x10040 */

static void print_format(const char *format, void *userdata) {
    int *count = (int *)userdata;
    printf("%s\n", format);
    (*count)++;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        fprintf(stderr, "\nDetects all matching formats for a file using libqemount.\n");
        fprintf(stderr, "libqemount version: %s\n", qemount_version());
        return 1;
    }

    const char *path = argv[1];

    FILE *f = fopen(path, "rb");
    if (!f) {
        perror(path);
        return 1;
    }

    unsigned char buffer[BUFFER_SIZE];
    size_t n = fread(buffer, 1, BUFFER_SIZE, f);
    fclose(f);

    if (n == 0) {
        fprintf(stderr, "%s: empty file\n", path);
        return 1;
    }

    int count = 0;
    qemount_detect_all(buffer, n, print_format, &count);

    return count > 0 ? 0 : 1;
}
