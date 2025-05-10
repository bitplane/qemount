#include "9p_session.h"
#include <stdlib.h>
#include <string.h>

Session* session_create(void) {
    Session *s = malloc(sizeof(Session));
    if (!s) return NULL;
    
    s->msize = 8192;  // Default
    strcpy(s->version, "9P2000");
    s->authenticated = 0;
    s->next_tag = 0;
    
    return s;
}

void session_destroy(Session *s) {
    free(s);
}

void session_set_msize(Session *s, uint32_t msize) {
    s->msize = msize;
}

void session_set_version(Session *s, const char *version) {
    strncpy(s->version, version, sizeof(s->version) - 1);
    s->version[sizeof(s->version) - 1] = '\0';
}

int session_check_version(Session *s, const char *version) {
    (void)s;  // Suppress unused parameter warning
    return strcmp(version, "9P2000") == 0;
}