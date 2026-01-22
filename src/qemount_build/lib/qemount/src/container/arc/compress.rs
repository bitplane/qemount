//! Unix compress (.Z) container reader
//!
//! The original Unix compress format using LZW compression.

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;
use weezl::{decode::Decoder, BitOrder};

/// Compress container - decompresses .Z content to expose inner stream
pub struct CompressContainer;

/// Static instance for registry
pub static COMPRESS: CompressContainer = CompressContainer;

impl Container for CompressContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let compressed = read_all(&*reader)?;

        // Verify magic and parse header
        if compressed.len() < 3 {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "too short"));
        }
        if compressed[0] != 0x1F || compressed[1] != 0x9D {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "bad magic"));
        }

        let flags = compressed[2];
        let max_bits = (flags & 0x1F) as u8;
        let _block_mode = (flags & 0x80) != 0;

        if max_bits < 9 || max_bits > 16 {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "invalid max_bits"));
        }

        // Decompress using LZW
        // Unix compress uses LSB-first bit order
        let mut decoder = Decoder::new(BitOrder::Lsb, max_bits);
        let mut decompressed = Vec::new();

        let result = decoder.decode_bytes(&compressed[3..], &mut decompressed);
        match result.status {
            Ok(_) => {}
            Err(e) => return Err(io::Error::new(io::ErrorKind::InvalidData, e.to_string())),
        }

        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
