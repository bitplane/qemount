#include <errno.h>
#include <fcntl.h>
#include <hfs/hfs_mount.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <termios.h>
#include <unistd.h>

#define CONSOLE_PATH "/dev/console"
#define MOUNT_PATH "/Volumes/QEMOUNT_TARGET"
#define SIMPLE9P_PATH "/usr/bin/simple9p"
#define STREAM64_PATH "/usr/bin/stream64"

static void
fail(const char *operation)
{
    dprintf(STDERR_FILENO, "qemount-init: %s: %s\n", operation,
        strerror(errno));
    for (;;)
        sleep(60);
}

static void
open_console(void)
{
    int console = open(CONSOLE_PATH, O_RDWR);
    if (console < 0)
        fail("open console");
    if (dup2(console, STDIN_FILENO) < 0
        || dup2(console, STDOUT_FILENO) < 0
        || dup2(console, STDERR_FILENO) < 0) {
        fail("attach console");
    }
    if (console > STDERR_FILENO)
        close(console);
}

static void
find_target(char *target, size_t size)
{
    struct stat root;
    unsigned int index;

    if (stat("/", &root) != 0)
        fail("identify root disk");

    for (index = 0; index < 10; index++) {
        struct stat device;
        char disk[32];
        char slice[32];
        int has_slice;

        snprintf(disk, sizeof(disk), "/dev/disk%u", index);
        if (stat(disk, &device) != 0)
            continue;
        if (device.st_rdev == root.st_dev)
            continue;
        snprintf(slice, sizeof(slice), "%ss1", disk);
        has_slice = stat(slice, &device) == 0;
        if (has_slice && device.st_rdev == root.st_dev)
            continue;
        snprintf(target, size, "%s", has_slice ? slice : disk);
        return;
    }
    errno = ENODEV;
    fail("find target disk");
}

static void
mount_target(const char *target)
{
    struct hfs_mount_args arguments;

    memset(&arguments, 0, sizeof(arguments));
    arguments.fspec = (char *)target;
    arguments.hfs_uid = 0;
    arguments.hfs_gid = 0;
    if (mount("hfs", MOUNT_PATH, MNT_RDONLY, &arguments) != 0)
        fail("mount target disk");
}

static void
raw_console(void)
{
    struct termios mode;

    if (tcgetattr(STDIN_FILENO, &mode) != 0)
        fail("read console mode");
    mode.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    mode.c_oflag &= ~OPOST;
    mode.c_cflag |= CS8;
    mode.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    mode.c_cc[VMIN] = 1;
    mode.c_cc[VTIME] = 0;
    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &mode) != 0)
        fail("set console mode");
}

int
main(void)
{
    char target[32];

    open_console();
    find_target(target, sizeof(target));
    mount_target(target);
    raw_console();
    if (write(STDOUT_FILENO, "QEMOUNT_9P_READY", 16) != 16)
        fail("announce 9P service");
    execl(STREAM64_PATH, STREAM64_PATH, CONSOLE_PATH, SIMPLE9P_PATH,
        "-p", "-", MOUNT_PATH, (char *)NULL);
    fail("start 9P service");
}
