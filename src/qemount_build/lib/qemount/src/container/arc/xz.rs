//! XZ container reader
//!
//! XZ is a compression wrapper containing a single decompressed stream.

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io::{self, Read};
use std::sync::Arc;
use xz2::read::XzDecoder;

/// XZ container - decompresses content to expose inner stream
pub struct XzContainer;

/// Static instance for registry
pub static XZ: XzContainer = XzContainer;

impl Container for XzContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;
        let mut decoder = XzDecoder::new(&compressed[..]);
        let mut decompressed = Vec::new();
        decoder.read_to_end(&mut decompressed)?;

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
