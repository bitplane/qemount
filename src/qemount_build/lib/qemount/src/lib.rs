//! qemount - Universal filesystem detection and mounting library

mod detect;
mod format;

use std::ffi::c_char;
use std::ffi::c_void;

/// Callback type for qemount_detect_all
pub type DetectCallback = extern "C" fn(format: *const c_char, userdata: *mut c_void);

/// Detect all matching formats from byte slice.
/// Calls the callback for each matching format with its name.
/// Format strings are static - do not free.
#[no_mangle]
pub extern "C" fn qemount_detect_all(
    data: *const u8,
    len: usize,
    callback: DetectCallback,
    userdata: *mut c_void,
) {
    if data.is_null() || len == 0 {
        return;
    }

    let slice = unsafe { std::slice::from_raw_parts(data, len) };

    for cstr in detect::detect_all(slice) {
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
