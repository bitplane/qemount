//! qemount - Universal filesystem detection and mounting library

mod checksum;
mod container;
mod detect;
mod format;

use std::ffi::{c_char, c_void, CStr};
use std::fs::File;
use std::io::{self, Read, Seek, SeekFrom};
use std::sync::{Arc, Mutex};

use detect::Reader;

/// File reader - wraps a File with mutex for thread-safe positional reads
struct FileReader {
    file: Mutex<File>,
}

impl Reader for FileReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        let mut file = self.file.lock().unwrap();
        file.seek(SeekFrom::Start(offset))?;
        file.read(buf)
    }

    fn size(&self) -> Option<u64> {
        let mut file = self.file.lock().unwrap();
        file.seek(SeekFrom::End(0)).ok()
    }
}

/// Get library version
/// Returned string is static - do not free.
#[no_mangle]
pub extern "C" fn qemount_version() -> *const c_char {
    static VERSION: &[u8] = b"0.1.0\0";
    VERSION.as_ptr() as *const c_char
}

/// Callback type for qemount_detect_tree
/// Called for each node in the detection tree.
/// - format: format name (static, do not free)
/// - index: index within parent (0 for root level)
/// - depth: nesting depth (0 for root level)
/// - userdata: user-provided context
pub type DetectTreeCallback =
    extern "C" fn(format: *const c_char, index: u32, depth: u32, userdata: *mut c_void);

/// Detect format tree from file path.
/// Recursively detects formats in containers (gzip, tar, partition tables, etc.)
/// Calls the callback for each detected format with its position in the tree.
#[no_mangle]
pub extern "C" fn qemount_detect_tree(
    path: *const c_char,
    callback: DetectTreeCallback,
    userdata: *mut c_void,
) {
    let path = match unsafe { CStr::from_ptr(path) }.to_str() {
        Ok(s) => s,
        Err(_) => return,
    };

    let file = match File::open(path) {
        Ok(f) => f,
        Err(_) => return,
    };

    let reader: Arc<dyn Reader + Send + Sync> = Arc::new(FileReader {
        file: Mutex::new(file),
    });
    let tree = detect::detect_tree(reader);

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
