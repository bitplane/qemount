#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

static const char ready[] = "[mountin-init] ready\n";
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
			(void) printf("[mountin-init] mounted %s as %s on %s\n",
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

static int
open_stream(const char *path)
{
	struct termios mode;
	int descriptor;

	descriptor = open(path, O_RDWR);
	if (descriptor < 0)
		return (-1);
	if (tcgetattr(descriptor, &mode) != 0) {
		(void) close(descriptor);
		return (-1);
	}
	mode.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR |
	    ICRNL | IXON);
	mode.c_oflag &= ~OPOST;
	mode.c_cflag &= ~(CSIZE | PARENB);
	mode.c_cflag |= CS8;
	mode.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN | ISIG);
	mode.c_cc[VMIN] = 1;
	mode.c_cc[VTIME] = 0;
	if (tcsetattr(descriptor, TCSAFLUSH, &mode) != 0) {
		(void) close(descriptor);
		return (-1);
	}
	return (descriptor);
}

int
main(void)
{
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
		(void) write(STDERR_FILENO, "[mountin-init] tmpfs mount failed\n",
		    sizeof ("[mountin-init] tmpfs mount failed\n") - 1);
	walk_devices("/devices");
	if (stream_device[0] == '\0') {
		(void) write(STDERR_FILENO,
		    "[mountin-init] 9P serial device not found\n",
		    sizeof ("[mountin-init] 9P serial device not found\n") - 1);
	} else {
		server = fork();
		if (server == 0) {
			int stream = open_stream(stream_device);

			if (stream < 0 || dup2(stream, STDIN_FILENO) < 0)
				_exit(126);
			if (stream != STDIN_FILENO)
				(void) close(stream);
			(void) execl("/sbin/9d", "9d", "-d", "-r",
			    "-p", "-", "/mnt", (char *)NULL);
			_exit(127);
		}
		if (server < 0)
			(void) write(STDERR_FILENO,
			    "[mountin-init] failed to start 9d\n",
			    sizeof ("[mountin-init] failed to start 9d\n") - 1);
		else if (waitpid(server, NULL, 0) == server)
			(void) write(STDERR_FILENO,
			    "[mountin-init] 9d stopped\n",
			    sizeof ("[mountin-init] 9d stopped\n") - 1);
	}
	for (;;)
		(void) pause();
}
