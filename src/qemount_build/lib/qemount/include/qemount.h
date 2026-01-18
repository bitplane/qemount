#ifndef QEMOUNT_H
#define QEMOUNT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Detect format from byte buffer.
 * Returns format path (e.g., "fs/ext4") or NULL if unknown.
 * Returned string is static - do not free.
 */
const char* qemount_detect(const unsigned char* data, size_t len);

/**
 * Get library version string.
 * Returned string is static - do not free.
 */
const char* qemount_version(void);

#ifdef __cplusplus
}
#endif

#endif /* QEMOUNT_H */
