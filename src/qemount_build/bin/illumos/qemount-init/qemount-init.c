#include <fcntl.h>
#include <unistd.h>

static const char ready[] = "[qemount-init] ready\n";

int
main(void)
{
	int console;

	console = open("/dev/console", O_RDWR);
	if (console >= 0) {
		(void) dup2(console, STDIN_FILENO);
		(void) dup2(console, STDOUT_FILENO);
		(void) dup2(console, STDERR_FILENO);
		if (console > STDERR_FILENO)
			(void) close(console);
	}

	(void) write(STDOUT_FILENO, ready, sizeof (ready) - 1);
	for (;;)
		(void) pause();
}
