/*
 * detect - Simple format detection CLI tool
 *
 * Links against libqemount.a via C to validate the C ABI.
 * Note: Currently Unix only (uses file descriptors).
 */

#ifdef _WIN32
#include <stdio.h>
int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    fprintf(stderr, "detect: not supported on Windows yet\n");
    return 1;
}
#else

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include "qemount.h"

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

    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        perror(path);
        return 1;
    }

    int count = 0;
    qemount_detect_fd(fd, print_format, &count);
    close(fd);

    return count > 0 ? 0 : 1;
}
#endif
