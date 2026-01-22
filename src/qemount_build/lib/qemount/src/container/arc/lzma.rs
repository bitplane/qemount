//! LZMA container reader
//!
//! Raw LZMA stream format, precursor to xz.

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// LZMA container - decompresses content to expose inner stream
pub struct LzmaContainer;

/// Static instance for registry
pub static LZMA: LzmaContainer = LzmaContainer;

impl Container for LzmaContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;
        let mut decompressed = Vec::new();

        lzma_rs::lzma_decompress(&mut &compressed[..], &mut decompressed)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e.to_string()))?;

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
