#ifndef QEMOUNT_H
#define QEMOUNT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Callback type for qemount_detect_fd.
 * Called once for each matching format.
 */
typedef void (*qemount_detect_callback)(const char* format, void* userdata);

#ifndef _WIN32
/**
 * Detect all matching formats from file descriptor.
 * Calls the callback for each matching format with its name.
 * Uses pread() internally - does not change file position.
 * Format strings are static - do not free.
 *
 * Note: Unix only. Not available on Windows.
 */
void qemount_detect_fd(
    int fd,
    qemount_detect_callback callback,
    void* userdata
);

/**
 * Callback type for qemount_detect_tree_fd.
 * Called once for each node in the detection tree.
 *
 * @param format Format name (e.g., "arc/gzip", "fs/ext4")
 * @param index Index within parent container (partition number, etc.)
 * @param depth Nesting depth (0 for root level)
 * @param userdata User-provided context
 */
typedef void (*qemount_detect_tree_callback)(
    const char* format,
    uint32_t index,
    uint32_t depth,
    void* userdata
);

/**
 * Detect format tree from file descriptor.
 * Recursively detects formats in containers (gzip, tar, partition tables, etc.)
 * Calls the callback for each detected format with its position in the tree.
 *
 * Note: Unix only. Not available on Windows.
 */
void qemount_detect_tree_fd(
    int fd,
    qemount_detect_tree_callback callback,
    void* userdata
);
#endif

/**
 * Get library version string.
 * Returned string is static - do not free.
 */
const char* qemount_version(void);

#ifdef __cplusplus
}
#endif

#endif /* QEMOUNT_H */
