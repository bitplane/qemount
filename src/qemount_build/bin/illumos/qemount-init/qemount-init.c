#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

static const char ready[] = "[qemount-init] ready\n";
static char stream_device[1024];
static unsigned int volume_count;

static int
has_suffix(const char *string, const char *suffix)
{
	size_t string_length = strlen(string);
	size_t suffix_length = strlen(suffix);

	return (string_length >= suffix_length &&
	    strcmp(string + string_length - suffix_length, suffix) == 0);
}

static void
try_mount(const char *device)
{
	static const char *filesystems[] = { "pcfs", "ufs", "hsfs" };
	struct stat status;
	char mountpoint[32];
	size_t index;

	if (lstat(device, &status) != 0 || !S_ISBLK(status.st_mode))
		return;
	if (snprintf(mountpoint, sizeof (mountpoint), "/mnt/%u",
	    volume_count) >= sizeof (mountpoint))
		return;
	if (mkdir(mountpoint, 0755) != 0)
		return;

	for (index = 0; index < sizeof (filesystems) / sizeof (*filesystems);
	    index++) {
		if (mount(device, mountpoint, MS_RDONLY | MS_DATA | MS_NOMNTTAB,
		    filesystems[index], NULL, 0) == 0) {
			(void) printf("[qemount-init] mounted %s as %s on %s\n",
			    device, filesystems[index], mountpoint);
			volume_count++;
			return;
		}
	}
	(void) rmdir(mountpoint);
}

static void
walk_devices(const char *path)
{
	struct dirent *entry;
	char child[1024];
	DIR *directory;

	if ((directory = opendir(path)) == NULL)
		return;

	while ((entry = readdir(directory)) != NULL) {
		if (strcmp(entry->d_name, ".") == 0 ||
		    strcmp(entry->d_name, "..") == 0)
			continue;
		if (snprintf(child, sizeof (child), "%s/%s", path,
		    entry->d_name) >= sizeof (child))
			continue;
		if (stream_device[0] == '\0' && strstr(child, "/asy@") != NULL &&
		    has_suffix(child, ",cu") && !has_suffix(child, ":a,cu"))
			(void) snprintf(stream_device, sizeof (stream_device), "%s",
			    child);
		try_mount(child);
		walk_devices(child);
	}
	(void) closedir(directory);
}

int
main(void)
{
	char address[sizeof (stream_device) + sizeof ("stream!")];
	int console;
	pid_t server;

	console = open("/dev/console", O_RDWR);
	if (console >= 0) {
		(void) dup2(console, STDIN_FILENO);
		(void) dup2(console, STDOUT_FILENO);
		(void) dup2(console, STDERR_FILENO);
		if (console > STDERR_FILENO)
			(void) close(console);
	}

	(void) write(STDOUT_FILENO, ready, sizeof (ready) - 1);
	if (mount("", "/mnt", MS_DATA | MS_NOMNTTAB, "tmpfs", NULL, 0) != 0)
		(void) write(STDERR_FILENO, "[qemount-init] tmpfs mount failed\n",
		    sizeof ("[qemount-init] tmpfs mount failed\n") - 1);
	walk_devices("/devices");
	if (stream_device[0] == '\0') {
		(void) write(STDERR_FILENO,
		    "[qemount-init] 9P serial device not found\n",
		    sizeof ("[qemount-init] 9P serial device not found\n") - 1);
	} else {
		(void) snprintf(address, sizeof (address), "stream!%s",
		    stream_device);
		server = fork();
		if (server == 0) {
			(void) execl("/sbin/simple9p", "simple9p", "-d", "-r",
			    "-p", address, "/mnt", (char *)NULL);
			_exit(127);
		}
		if (server < 0)
			(void) write(STDERR_FILENO,
			    "[qemount-init] failed to start simple9p\n",
			    sizeof ("[qemount-init] failed to start simple9p\n") - 1);
		else if (waitpid(server, NULL, 0) == server)
			(void) write(STDERR_FILENO,
			    "[qemount-init] simple9p stopped\n",
			    sizeof ("[qemount-init] simple9p stopped\n") - 1);
	}
	for (;;)
		(void) pause();
}
