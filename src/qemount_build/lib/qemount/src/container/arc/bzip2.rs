//! Bzip2 container reader
//!
//! Bzip2 is a compression wrapper containing a single decompressed stream.

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use bzip2::read::BzDecoder;
use std::io::{self, Read};
use std::sync::Arc;

/// Bzip2 container - decompresses content to expose inner stream
pub struct Bzip2Container;

/// Static instance for registry
pub static BZIP2: Bzip2Container = Bzip2Container;

impl Container for Bzip2Container {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;
        let mut decoder = BzDecoder::new(&compressed[..]);
        let mut decompressed = Vec::new();
        decoder.read_to_end(&mut decompressed)?;

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
