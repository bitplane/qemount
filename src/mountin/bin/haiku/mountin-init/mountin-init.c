#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <fs_volume.h>


#define SERIAL_PATH "/dev/ports/pc_serial0"
#define NINED_PATH "/system/non-packaged/bin/9d"
#define DEBUG_PATH "/dev/dprintf"


static void
log_message(const char* format, ...)
{
	int fd = open(DEBUG_PATH, O_WRONLY);
	if (fd < 0)
		return;

	char message[512];
	va_list args;
	va_start(args, format);
	vsnprintf(message, sizeof(message), format, args);
	va_end(args);
	write(fd, "mountin: ", 9);
	write(fd, message, strlen(message));
	write(fd, "\n", 1);
	close(fd);
}


static int
wait_for(pid_t child)
{
	int status;
	while (waitpid(child, &status, 0) < 0) {
		if (errno != EINTR)
			return -1;
	}

	if (WIFEXITED(status))
		return WEXITSTATUS(status);
	return -1;
}


static int
run(char* const argv[])
{
	pid_t child = fork();
	if (child < 0)
		return -1;

	if (child == 0) {
		execv(argv[0], argv);
		_exit(127);
	}

	return wait_for(child);
}


static unsigned int sVolumeIndex;


static void
mount_device(const char* device)
{
	char mountPoint[64];
	snprintf(mountPoint, sizeof(mountPoint), "/mountin-%u", sVolumeIndex);
	if (mkdir(mountPoint, 0755) != 0)
		return;

	dev_t volume = fs_mount_volume(mountPoint, device, NULL, 0, NULL);
	if (volume < 0) {
		volume = fs_mount_volume(mountPoint, device, NULL,
			B_MOUNT_READ_ONLY, NULL);
	}
	if (volume >= 0) {
		log_message("mounted %s at %s", device, mountPoint);
		sVolumeIndex++;
	} else
		rmdir(mountPoint);
}


static void
mount_devices(const char* directory)
{
	DIR* dir = opendir(directory);
	if (dir == NULL)
		return;

	struct dirent* entry;
	while ((entry = readdir(dir)) != NULL) {
		if (strcmp(entry->d_name, ".") == 0
			|| strcmp(entry->d_name, "..") == 0) {
			continue;
		}

		char path[PATH_MAX];
		if (snprintf(path, sizeof(path), "%s/%s", directory,
				entry->d_name) >= (int)sizeof(path)) {
			continue;
		}

		struct stat stat;
		if (lstat(path, &stat) != 0)
			continue;
		if (S_ISDIR(stat.st_mode))
			mount_devices(path);
		else if (!S_ISLNK(stat.st_mode))
			mount_device(path);
	}
	closedir(dir);
}


int
main(void)
{
	log_message("mountin-init started");
	while (access(SERIAL_PATH, F_OK) != 0)
		sleep(1);

	pid_t mountChild = fork();
	if (mountChild == 0) {
		mount_devices("/dev/disk");
		_exit(0);
	}
	if (mountChild < 0)
		log_message("could not start volume mounting");

	char* nined[] = {
		NINED_PATH, "-p", "stream!" SERIAL_PATH, "/", NULL
	};
	for (;;) {
		log_message("serving / over " SERIAL_PATH);
		int status = run(nined);
		log_message("9d exited with status %d; restarting", status);
		sleep(1);
	}
}
