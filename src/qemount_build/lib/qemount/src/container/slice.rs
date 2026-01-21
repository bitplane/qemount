//! Slice reader - provides bounded access to a region of a parent reader

use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Reader that provides access to a bounded slice of another reader.
pub struct SliceReader {
    parent: Arc<dyn Reader + Send + Sync>,
    offset: u64,
    length: u64,
}

impl SliceReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>, offset: u64, length: u64) -> Self {
        Self { parent, offset, length }
    }
}

impl Reader for SliceReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.length {
            return Ok(0);
        }
        let available = (self.length - offset) as usize;
        let to_read = buf.len().min(available);
        self.parent.read_at(self.offset + offset, &mut buf[..to_read])
    }
}
