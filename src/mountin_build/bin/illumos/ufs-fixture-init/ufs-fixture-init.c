#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

static char block_device[1024];
static char raw_device[1024];

static void
message(const char *text)
{
	(void) write(STDOUT_FILENO, text, strlen(text));
}

static void
find_disk(const char *path)
{
	struct dirent *entry;
	struct stat status;
	char child[1024];
	DIR *directory;

	if (raw_device[0] != '\0' || (directory = opendir(path)) == NULL)
		return;
	while ((entry = readdir(directory)) != NULL && raw_device[0] == '\0') {
		if (strcmp(entry->d_name, ".") == 0 ||
		    strcmp(entry->d_name, "..") == 0)
			continue;
		if (snprintf(child, sizeof (child), "%s/%s", path,
		    entry->d_name) >= sizeof (child))
			continue;
		if (lstat(child, &status) == 0 && S_ISCHR(status.st_mode) &&
		    strstr(child, "/blkdev@") != NULL &&
		    strlen(child) >= 6 &&
		    strcmp(child + strlen(child) - 6, ":q,raw") == 0) {
			(void) snprintf(raw_device, sizeof (raw_device), "%s", child);
			(void) snprintf(block_device, sizeof (block_device), "%.*s",
			    (int)(strlen(child) - 4), child);
			break;
		}
		find_disk(child);
	}
	(void) closedir(directory);
}

static int
copy_file(const char *source, const char *destination, mode_t mode)
{
	char buffer[8192];
	ssize_t count;
	int input;
	int output;

	if ((input = open(source, O_RDONLY)) < 0)
		return (-1);
	output = open(destination, O_WRONLY | O_CREAT | O_TRUNC, mode & 0777);
	if (output < 0) {
		(void) close(input);
		return (-1);
	}
	while ((count = read(input, buffer, sizeof (buffer))) > 0) {
		char *position = buffer;
		ssize_t remaining = count;

		while (remaining > 0) {
			ssize_t written = write(output, position, remaining);
			if (written <= 0) {
				(void) close(input);
				(void) close(output);
				return (-1);
			}
			position += written;
			remaining -= written;
		}
	}
	(void) close(input);
	(void) close(output);
	return (count < 0 ? -1 : 0);
}

static int
copy_tree(const char *source, const char *destination)
{
	struct dirent *entry;
	struct stat status;
	char source_child[1024];
	char destination_child[1024];
	char target[1024];
	DIR *directory;
	ssize_t length;

	if (lstat(source, &status) != 0)
		return (-1);
	if (S_ISLNK(status.st_mode)) {
		length = readlink(source, target, sizeof (target) - 1);
		if (length < 0)
			return (-1);
		target[length] = '\0';
		return (symlink(target, destination));
	}
	if (!S_ISDIR(status.st_mode))
		return (copy_file(source, destination, status.st_mode));
	if (mkdir(destination, status.st_mode & 0777) != 0)
		return (-1);
	if ((directory = opendir(source)) == NULL)
		return (-1);
	while ((entry = readdir(directory)) != NULL) {
		if (strcmp(entry->d_name, ".") == 0 ||
		    strcmp(entry->d_name, "..") == 0)
			continue;
		if (snprintf(source_child, sizeof (source_child), "%s/%s", source,
		    entry->d_name) >= sizeof (source_child) ||
		    snprintf(destination_child, sizeof (destination_child), "%s/%s",
		    destination, entry->d_name) >= sizeof (destination_child) ||
		    copy_tree(source_child, destination_child) != 0) {
			(void) closedir(directory);
			return (-1);
		}
	}
	(void) closedir(directory);
	return (0);
}

int
main(void)
{
	char hello[14];
	int console;
	int file;
	int status;
	pid_t child;

	console = open("/dev/console", O_RDWR);
	if (console >= 0) {
		(void) dup2(console, STDIN_FILENO);
		(void) dup2(console, STDOUT_FILENO);
		(void) dup2(console, STDERR_FILENO);
		if (console > STDERR_FILENO)
			(void) close(console);
	}
	message("[ufs-fixture] starting\n");
	find_disk("/devices");
	if (raw_device[0] == '\0')
		goto failed;
	(void) printf("[ufs-fixture] formatting %s\n", raw_device);
	(void) fflush(stdout);
	child = fork();
	if (child == 0) {
		(void) execl("/sbin/mkfs.ufs", "mkfs.ufs", raw_device, "65536",
		    (char *)NULL);
		_exit(127);
	}
	if (child < 0 || waitpid(child, &status, 0) != child)
		goto failed;
	if (WIFSIGNALED(status)) {
		(void) printf("[ufs-fixture] mkfs signal %d\n", WTERMSIG(status));
		goto failed;
	}
	if (!WIFEXITED(status))
		goto failed;
	if (WEXITSTATUS(status) != 0) {
		(void) printf("[ufs-fixture] mkfs exit %d\n", WEXITSTATUS(status));
		goto failed;
	}
	message("[ufs-fixture] formatted\n");
	if (mount(block_device, "/mnt", MS_DATA | MS_NOMNTTAB, "ufs", NULL,
	    0) != 0)
		goto failed;
	if (copy_tree("/TestData/basic", "/mnt/basic") != 0)
		goto failed;
	(void) sync();
	if (umount("/mnt") != 0 ||
	    mount(block_device, "/mnt", MS_RDONLY | MS_DATA | MS_NOMNTTAB,
	    "ufs", NULL, 0) != 0)
		goto failed;
	file = open("/mnt/basic/hello.txt", O_RDONLY);
	if (file < 0 || read(file, hello, sizeof (hello)) != sizeof (hello) ||
	    memcmp(hello, "Hello, world!\n", sizeof (hello)) != 0)
		goto failed;
	(void) close(file);
	(void) umount("/mnt");
	message("illumos UFS fixture complete\n");
	for (;;)
		(void) pause();

failed:
	message("illumos UFS fixture failed\n");
	for (;;)
		(void) pause();
}
