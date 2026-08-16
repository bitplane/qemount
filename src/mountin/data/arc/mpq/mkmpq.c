/*
 * Create a minimal MPQ archive from a directory of files.
 * Usage: mkmpq output.mpq directory/
 *
 * Links against StormLib (https://github.com/ladislav-zezula/StormLib).
 */

#include <StormLib.h>
#include <stdio.h>
#include <dirent.h>
#include <string.h>
#include <sys/stat.h>

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s output.mpq dir/\n", argv[0]);
        return 1;
    }

    HANDLE hMpq;
    if (!SFileCreateArchive(argv[1], MPQ_CREATE_ARCHIVE_V2, 64, &hMpq)) {
        fprintf(stderr, "Failed to create archive\n");
        return 1;
    }

    DIR *d = opendir(argv[2]);
    if (!d) {
        perror("opendir");
        SFileCloseArchive(hMpq);
        return 1;
    }

    struct dirent *ent;
    char path[512];
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        snprintf(path, sizeof(path), "%s/%s", argv[2], ent->d_name);
        struct stat st;
        if (stat(path, &st) || !S_ISREG(st.st_mode)) continue;
        if (!SFileAddFileEx(hMpq, path, ent->d_name,
                            MPQ_FILE_COMPRESS,
                            MPQ_COMPRESSION_ZLIB,
                            MPQ_COMPRESSION_ZLIB)) {
            fprintf(stderr, "Failed to add %s\n", ent->d_name);
        }
    }
    closedir(d);

    SFileCompactArchive(hMpq, NULL, 0);
    SFileCloseArchive(hMpq);
    return 0;
}
