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
#define MOUNT_PATH "/Volumes/MOUNTIN_TARGET"
#define NINED_PATH "/usr/bin/9d"
#define STREAM64_PATH "/usr/bin/stream64"
#define MAX_DISKS 10
#define MAX_SLICES 128

static void
fail(const char *operation)
{
    dprintf(STDERR_FILENO, "mountin-init: %s: %s\n", operation,
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

static int
device_is(const char *path, dev_t device)
{
    struct stat status;

    return stat(path, &status) == 0 && status.st_rdev == device;
}

static int
is_root_disk(unsigned int disk, dev_t root)
{
    char path[32];
    unsigned int slice;

    snprintf(path, sizeof(path), "/dev/disk%u", disk);
    if (device_is(path, root))
        return 1;
    for (slice = 1; slice <= MAX_SLICES; slice++) {
        snprintf(path, sizeof(path), "/dev/disk%us%u", disk, slice);
        if (device_is(path, root))
            return 1;
    }
    return 0;
}

static int
try_mount(const char *target)
{
    struct hfs_mount_args arguments;

    memset(&arguments, 0, sizeof(arguments));
    arguments.fspec = (char *)target;
    arguments.hfs_uid = 0;
    arguments.hfs_gid = 0;
    return mount("hfs", MOUNT_PATH, MNT_RDONLY, &arguments) == 0;
}

static void
mount_target(void)
{
    struct stat root;
    unsigned int disk;
    int mount_error = ENODEV;

    if (stat("/", &root) != 0)
        fail("identify root disk");

    for (disk = 0; disk < MAX_DISKS; disk++) {
        char path[32];
        unsigned int slice;

        snprintf(path, sizeof(path), "/dev/disk%u", disk);
        if (access(path, F_OK) != 0 || is_root_disk(disk, root.st_dev))
            continue;
        for (slice = 1; slice <= MAX_SLICES; slice++) {
            snprintf(path, sizeof(path), "/dev/disk%us%u", disk, slice);
            if (access(path, F_OK) == 0) {
                if (try_mount(path))
                    return;
                mount_error = errno;
            }
        }
        snprintf(path, sizeof(path), "/dev/disk%u", disk);
        if (try_mount(path))
            return;
        mount_error = errno;
    }
    errno = mount_error;
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
    open_console();
    mount_target();
    raw_console();
    if (write(STDOUT_FILENO, "MOUNTIN_9P_READY", 16) != 16)
        fail("announce 9P service");
    execl(STREAM64_PATH, STREAM64_PATH, CONSOLE_PATH, NINED_PATH,
        "-p", "-", MOUNT_PATH, (char *)NULL);
    fail("start 9P service");
}
