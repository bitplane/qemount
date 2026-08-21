#include <sys/endian.h>
#include <sys/ioctl.h>

#include <dev/ic/qemufwcfgio.h>

#include <err.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct fwcfg_file {
	uint32_t size;
	uint16_t selector;
	uint16_t reserved;
	char name[56];
} __packed;

static void
read_exact(int fd, void *buffer, size_t size)
{
	char *cursor = buffer;

	while (size != 0) {
		ssize_t count = read(fd, cursor, size);
		if (count == -1)
			err(EXIT_FAILURE, "read");
		if (count == 0)
			errx(EXIT_FAILURE, "unexpected end of fw_cfg data");
		cursor += count;
		size -= (size_t)count;
	}
}

int
main(int argc, char **argv)
{
	struct fwcfg_file file;
	uint32_t count;
	uint16_t selector = FW_CFG_FILE_DIR;
	int fd;

	if (argc != 2)
		errx(EXIT_FAILURE, "usage: mountin-fwcfg name");

	fd = open("/dev/qemufwcfg0", O_RDONLY);
	if (fd == -1)
		err(EXIT_FAILURE, "/dev/qemufwcfg0");
	if (ioctl(fd, FWCFGIO_SET_INDEX, &selector) == -1)
		err(EXIT_FAILURE, "select fw_cfg directory");
	read_exact(fd, &count, sizeof(count));
	count = be32toh(count);

	while (count-- != 0) {
		read_exact(fd, &file, sizeof(file));
		if (strncmp(file.name, argv[1], sizeof(file.name)) != 0)
			continue;
		selector = be16toh(file.selector);
		if (ioctl(fd, FWCFGIO_SET_INDEX, &selector) == -1)
			err(EXIT_FAILURE, "select %s", argv[1]);
		file.size = be32toh(file.size);
		while (file.size-- != 0) {
			char byte;
			read_exact(fd, &byte, 1);
			if (write(STDOUT_FILENO, &byte, 1) != 1)
				err(EXIT_FAILURE, "write");
		}
		return EXIT_SUCCESS;
	}

	errx(EXIT_FAILURE, "fw_cfg file not found: %s", argv[1]);
}
