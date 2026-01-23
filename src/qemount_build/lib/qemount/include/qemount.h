#ifndef QEMOUNT_H
#define QEMOUNT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Callback type for qemount_detect_tree.
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
 * Detect format tree from file path.
 * Recursively detects formats in containers (gzip, tar, partition tables, etc.)
 * Calls the callback for each detected format with its position in the tree.
 *
 * @param path Path to file to detect (UTF-8 encoded)
 * @param callback Function called for each detected format
 * @param userdata Passed through to callback
 */
void qemount_detect_tree(
    const char* path,
    qemount_detect_tree_callback callback,
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
