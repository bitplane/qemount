//! ATR (Atari 8-bit disk image) container reader
//!
//! ATR is a 16-byte header wrapped around a raw Atari sector dump. The header
//! records the magic word, the data size in 16-byte paragraphs and the sector
//! size; this container strips the header and yields the sector data as a single
//! raw-disk child, which the recursion engine can then detect (Atari DOS).
//!
//! Format reference: docs/format/disk/atr.md

use crate::container::{slice::SliceReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const MAGIC: u16 = 0x0296; // little-endian word at offset 0 (sum of "NICKATARI")
const HEADER_LEN: usize = 16;

fn invalid(msg: &str) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, msg)
}

fn le16(b: &[u8], off: usize) -> u16 {
    u16::from_le_bytes([b[off], b[off + 1]])
}

/// Parse the 16-byte header and return the sector-data length in bytes.
fn parse_header(reader: &dyn Reader) -> io::Result<u64> {
    let mut hdr = [0u8; HEADER_LEN];
    if reader.read_at(0, &mut hdr)? != HEADER_LEN {
        return Err(invalid("ATR header truncated"));
    }
    if le16(&hdr, 0) != MAGIC {
        return Err(invalid("not an ATR image"));
    }

    // Data size is stored in 16-byte "paragraphs", split into low and high words.
    let paragraphs = le16(&hdr, 2) as u64 | ((le16(&hdr, 6) as u64) << 16);
    let data_len = paragraphs * 16;
    if data_len == 0 {
        return Err(invalid("ATR declares zero-length disk data"));
    }

    if let Some(total) = reader.size() {
        if HEADER_LEN as u64 + data_len > total {
            return Err(invalid("ATR disk data runs past end of file"));
        }
    }
    Ok(data_len)
}

pub struct AtrContainer;

pub static ATR: AtrContainer = AtrContainer;

impl Container for AtrContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let data_len = parse_header(&*reader)?;
        Ok(vec![Child {
            index: 0,
            offset: HEADER_LEN as u64,
            reader: Arc::new(SliceReader::new(
                Arc::clone(&reader),
                HEADER_LEN as u64,
                data_len,
            )),
        }])
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::container::BytesReader;

    /// Build a minimal ATR: 16-byte header + `payload` sector data.
    fn sample(payload: &[u8]) -> Vec<u8> {
        let paragraphs = (payload.len() / 16) as u32;
        let mut img = vec![0u8; HEADER_LEN];
        img[0..2].copy_from_slice(&MAGIC.to_le_bytes());
        img[2..4].copy_from_slice(&((paragraphs & 0xFFFF) as u16).to_le_bytes());
        img[4..6].copy_from_slice(&128u16.to_le_bytes()); // sector size
        img[6..8].copy_from_slice(&((paragraphs >> 16) as u16).to_le_bytes());
        img.extend_from_slice(payload);
        img
    }

    #[test]
    fn strips_header_to_one_child() {
        let payload = vec![0xABu8; 256];
        let reader = Arc::new(BytesReader::new(sample(&payload)));
        let children = ATR.children(reader).unwrap();
        assert_eq!(children.len(), 1);
        assert_eq!(children[0].offset, HEADER_LEN as u64);

        let mut buf = [0u8; 256];
        let n = children[0].reader.read_at(0, &mut buf).unwrap();
        assert_eq!(n, 256);
        assert_eq!(buf[..], payload[..]);
        assert_eq!(children[0].reader.size(), Some(256));
    }

    #[test]
    fn rejects_bad_magic() {
        let mut bad = sample(&[0u8; 128]);
        bad[0] = 0xFF;
        assert!(ATR.children(Arc::new(BytesReader::new(bad))).is_err());
    }

    #[test]
    fn rejects_data_past_eof() {
        let mut img = sample(&[0u8; 128]);
        // Claim far more paragraphs than the file holds.
        img[2..4].copy_from_slice(&0xFFFFu16.to_le_bytes());
        assert!(ATR.children(Arc::new(BytesReader::new(img))).is_err());
    }

    /// Full registry path: the 0x0296 magic rule must dispatch to this container
    /// and strip the header to exactly one raw child.
    #[test]
    fn detect_chain_strips_header() {
        let reader = Arc::new(BytesReader::new(sample(&[0u8; 256])));
        let tree = crate::detect::detect_tree(reader);
        let node = tree
            .iter()
            .find(|n| n.format.to_str() == Ok("disk/atr"))
            .expect("disk/atr not detected");
        assert_eq!(node.children.len(), 1, "expected one raw child");
    }
}
