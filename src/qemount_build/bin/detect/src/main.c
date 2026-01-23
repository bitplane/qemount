/*
 * detect - Simple format detection CLI tool
 *
 * Links against libqemount.a via C to validate the C ABI.
 */

#include <stdint.h>
#include <stdio.h>
#include "qemount.h"

static void print_format_tree(const char *format, uint32_t index,
                              uint32_t depth, void *userdata) {
    int *count = (int *)userdata;
    for (uint32_t i = 0; i < depth; i++)
        printf("  ");
    if (depth > 0)
        printf("[%u] ", index);
    printf("%s\n", format);
    (*count)++;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file>...\n", argv[0]);
        fprintf(stderr, "\nDetects format tree for files using libqemount.\n");
        fprintf(stderr, "Recursively detects formats in containers.\n");
        fprintf(stderr, "libqemount version: %s\n", qemount_version());
        return 1;
    }

    int total = 0;
    for (int i = 1; i < argc; i++) {
        const char *path = argv[i];

        if (argc > 2)
            printf("%s:\n", path);

        int count = 0;
        qemount_detect_tree(path, print_format_tree, &count);
        total += count;

        if (argc > 2 && i < argc - 1)
            printf("\n");
    }

    return total > 0 ? 0 : 1;
}
