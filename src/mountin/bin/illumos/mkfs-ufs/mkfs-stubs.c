#include <stdlib.h>
#include <string.h>
#include <sys/asynch.h>
#include <sys/efi_partition.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/vtoc.h>
#include <unistd.h>

offset_t
mountin_llseek(int descriptor, offset_t offset, int whence)
{
	return ((offset_t)lseek(descriptor, (off_t)offset, whence));
}

static aio_result_t *completed;

int
mountin_aiowrite(int descriptor, caddr_t buffer, int size, off_t offset,
    int whence, aio_result_t *result)
{
	ssize_t written;

	if (lseek(descriptor, offset, whence) == (off_t)-1)
		written = -1;
	else
		written = write(descriptor, buffer, size);
	result->aio_return = written;
	completed = result;
	return (0);
}

aio_result_t *
mountin_aiowait(struct timeval *timeout)
{
	aio_result_t *result = completed;

	(void) timeout;
	completed = NULL;
	return (result);
}

char *
getfullblkname(char *path)
{
	size_t length = strlen(path);
	char *block;

	if (length < 4 || strcmp(path + length - 4, ",raw") != 0)
		return (strdup(path));
	block = malloc(length - 3);
	if (block == NULL)
		return (NULL);
	(void) memcpy(block, path, length - 4);
	block[length - 4] = '\0';
	return (block);
}

int
read_extvtoc(int fd, struct extvtoc *vtoc)
{
	(void) fd;
	(void) vtoc;
	return (-1);
}

int
efi_alloc_and_read(int fd, dk_gpt_t **gpt)
{
	(void) fd;
	(void) gpt;
	return (-1);
}

void
efi_free(dk_gpt_t *gpt)
{
	(void) gpt;
}

int
rl_roll_log(char *path)
{
	(void) path;
	return (0);
}

int
rl_log_control(char *path, int request)
{
	(void) path;
	(void) request;
	return (0);
}
