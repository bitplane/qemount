#ifndef QEMOUNT_H
#define QEMOUNT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Callback type for qemount_detect_all.
 * Called once for each matching format.
 */
typedef void (*qemount_detect_callback)(const char* format, void* userdata);

/**
 * Detect all matching formats from byte buffer.
 * Calls the callback for each matching format with its name.
 * Format strings are static - do not free.
 */
void qemount_detect_all(
    const unsigned char* data,
    size_t len,
    qemount_detect_callback callback,
    void* userdata
);

/**
 * Get library version string.
 * Returned string is static - do not free.
 */
const char* qemount_version(void);

#ifdef __cplusplus
}
#endif

#endif /* QEMOUNT_H */
