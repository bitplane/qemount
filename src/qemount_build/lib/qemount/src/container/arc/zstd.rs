//! Zstandard container reader
//!
//! Zstd is a compression wrapper containing a single decompressed stream.

use crate::container::{read_all, read_to_end_limited, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Zstd container - decompresses content to expose inner stream
pub struct ZstdContainer;

/// Static instance for registry
pub static ZSTD: ZstdContainer = ZstdContainer;

impl Container for ZstdContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;
        let decoder = zstd::stream::read::Decoder::new(&compressed[..])?;
        let decompressed = read_to_end_limited(decoder)?;

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
