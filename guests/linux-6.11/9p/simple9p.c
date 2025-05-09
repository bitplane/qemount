#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: simple9p <directory>\n");
    return 1;
  }
  printf("Simple 9P server starting for directory: %s\n", argv[1]);
  while(1) {
    char buffer[4096];
    ssize_t n = read(0, buffer, sizeof(buffer));
    if (n <= 0) break;
    write(1, buffer, n);
  }
  return 0;
}