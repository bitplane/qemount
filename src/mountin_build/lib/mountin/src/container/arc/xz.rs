//! XZ container reader
//!
//! XZ is a compression wrapper containing a single decompressed stream.

use crate::container::{read_all, BytesReader, Child, Container, LimitedBuffer};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// XZ container - decompresses content to expose inner stream
pub struct XzContainer;

/// Static instance for registry
pub static XZ: XzContainer = XzContainer;

impl Container for XzContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;
        let mut decompressed = LimitedBuffer::new();

        lzma_rs::xz_decompress(&mut &compressed[..], &mut decompressed)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e.to_string()))?;

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed.into_inner())),
        }])
    }
}
