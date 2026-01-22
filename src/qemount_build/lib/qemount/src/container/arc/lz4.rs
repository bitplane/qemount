//! LZ4 container reader
//!
//! LZ4 frame format - fast compression used in ZFS, Linux kernel, etc.

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io::{self, Read};
use std::sync::Arc;

/// LZ4 container - decompresses content to expose inner stream
pub struct Lz4Container;

/// Static instance for registry
pub static LZ4: Lz4Container = Lz4Container;

impl Container for Lz4Container {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;

        let mut decoder = lz4_flex::frame::FrameDecoder::new(&compressed[..]);
        let mut decompressed = Vec::new();
        decoder.read_to_end(&mut decompressed)?;

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
