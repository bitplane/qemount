//! qemount - Universal filesystem detection and mounting library

mod container;
mod detect;
mod format;

use std::ffi::c_char;
use std::ffi::c_void;
use std::io;

use detect::Reader;

/// File descriptor reader - wraps a raw fd and uses pread for positional reads
#[cfg(unix)]
struct FdReader {
    fd: std::os::unix::io::RawFd,
}

#[cfg(unix)]
impl Reader for FdReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        let n = unsafe {
            libc::pread(
                self.fd,
                buf.as_mut_ptr() as *mut libc::c_void,
                buf.len(),
                offset as libc::off_t,
            )
        };
        if n < 0 {
            Err(io::Error::last_os_error())
        } else {
            Ok(n as usize)
        }
    }
}

/// Callback type for qemount_detect_fd
pub type DetectCallback = extern "C" fn(format: *const c_char, userdata: *mut c_void);

/// Detect all matching formats from file descriptor.
/// Calls the callback for each matching format with its name.
/// Uses pread() internally - does not change file position.
/// Format strings are static - do not free.
#[cfg(unix)]
#[no_mangle]
pub extern "C" fn qemount_detect_fd(
    fd: std::os::unix::io::RawFd,
    callback: DetectCallback,
    userdata: *mut c_void,
) {
    let reader = FdReader { fd };

    for cstr in detect::detect_all(&reader) {
        callback(cstr.as_ptr(), userdata);
    }
}

/// Get library version
/// Returned string is static - do not free.
#[no_mangle]
pub extern "C" fn qemount_version() -> *const c_char {
    static VERSION: &[u8] = b"0.1.0\0";
    VERSION.as_ptr() as *const c_char
}

/// Callback type for qemount_detect_tree_fd
/// Called for each node in the detection tree.
/// - format: format name (static, do not free)
/// - index: index within parent (0 for root level)
/// - depth: nesting depth (0 for root level)
/// - userdata: user-provided context
pub type DetectTreeCallback =
    extern "C" fn(format: *const c_char, index: u32, depth: u32, userdata: *mut c_void);

/// Detect format tree from file descriptor.
/// Recursively detects formats in containers (gzip, tar, partition tables, etc.)
/// Calls the callback for each detected format with its position in the tree.
#[cfg(unix)]
#[no_mangle]
pub extern "C" fn qemount_detect_tree_fd(
    fd: std::os::unix::io::RawFd,
    callback: DetectTreeCallback,
    userdata: *mut c_void,
) {
    let reader = FdReader { fd };
    let tree = detect::detect_tree(&reader);

    fn walk_tree(
        nodes: &[detect::DetectNode],
        depth: u32,
        callback: DetectTreeCallback,
        userdata: *mut c_void,
    ) {
        for node in nodes {
            callback(node.format.as_ptr(), node.index, depth, userdata);
            walk_tree(&node.children, depth + 1, callback, userdata);
        }
    }

    walk_tree(&tree, 0, callback, userdata);
}
