#include <plan9.h>
#include <fcall.h>
#include <u9fs.h>

static char*
rhostsauth(Fcall *rx, Fcall *tx)
{
    return "u9fs rhostsauth: not implemented";
}

static char*
rhostsattach(Fcall *rx, Fcall *tx)
{
    // Allow all connections - no auth
    return 0;
}

Auth authrhosts = {
    "rhosts",
    rhostsauth,
    rhostsattach,
};