//! qemount - Universal filesystem detection and mounting library

mod detect;
mod format;

use std::ffi::c_char;
use std::ptr;

/// Detect format from byte slice
/// Returns format path (e.g., "fs/ext4") or null if unknown.
/// Returned string is static - do not free.
#[no_mangle]
pub extern "C" fn qemount_detect(data: *const u8, len: usize) -> *const c_char {
    if data.is_null() || len == 0 {
        return ptr::null();
    }

    let slice = unsafe { std::slice::from_raw_parts(data, len) };

    match detect::detect(slice) {
        Some(cstr) => cstr.as_ptr(),
        None => ptr::null(),
    }
}

/// Get library version
/// Returned string is static - do not free.
#[no_mangle]
pub extern "C" fn qemount_version() -> *const c_char {
    static VERSION: &[u8] = b"0.1.0\0";
    VERSION.as_ptr() as *const c_char
}
