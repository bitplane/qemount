//! qemount - Universal filesystem detection and mounting library

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
