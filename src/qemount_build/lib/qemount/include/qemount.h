#ifndef QEMOUNT_H
#define QEMOUNT_H

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
