//! Gzip container reader
//!
//! Gzip is a compression wrapper containing a single decompressed stream.

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use flate2::read::GzDecoder;
use std::io::{self, Read};
use std::sync::Arc;

/// Gzip container - decompresses content to expose inner stream
pub struct GzipContainer;

/// Static instance for registry
pub static GZIP: GzipContainer = GzipContainer;

impl Container for GzipContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;
        let mut decoder = GzDecoder::new(&compressed[..]);
        let mut decompressed = Vec::new();
        decoder.read_to_end(&mut decompressed)?;

        Ok(vec![Child {
            index: 0,
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
