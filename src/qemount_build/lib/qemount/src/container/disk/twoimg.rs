//! 2IMG / 2MG (Apple IIgs / Macintosh) disk image reader
//!
//! 2IMG is a self-describing header wrapped around a raw sector dump. The
//! 64-byte header records where the disk data starts and how long it is; this
//! container strips the header and yields that region as a single raw-disk
//! child, which the recursion engine then detects (HFS / ProDOS for
//! ProDOS-order payloads).
//!
//! Format reference: docs/format/disk/2img.md

use crate::container::{slice::SliceReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const MAGIC: &[u8; 4] = b"2IMG";
const HEADER_MIN: usize = 0x20; // through the data-length field

fn invalid(msg: &str) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, msg)
}

fn le32(b: &[u8], off: usize) -> u32 {
    u32::from_le_bytes([b[off], b[off + 1], b[off + 2], b[off + 3]])
}

/// Parse the header and return (data_offset, data_length).
fn parse_header(reader: &dyn Reader) -> io::Result<(u64, u64)> {
    let mut hdr = [0u8; HEADER_MIN];
    if reader.read_at(0, &mut hdr)? != HEADER_MIN {
        return Err(invalid("2IMG header truncated"));
    }
    if &hdr[..4] != MAGIC {
        return Err(invalid("not a 2IMG image"));
    }

    let data_off = le32(&hdr, 0x18) as u64;
    let data_len = le32(&hdr, 0x1C) as u64;
    if data_len == 0 {
        return Err(invalid("2IMG declares zero-length disk data"));
    }

    // The data region must lie within the file.
    if let Some(total) = reader.size() {
        if data_off >= total || data_off + data_len > total {
            return Err(invalid("2IMG disk data runs past end of file"));
        }
    }
    Ok((data_off, data_len))
}

pub struct TwoImgContainer;

pub static TWOIMG: TwoImgContainer = TwoImgContainer;

impl Container for TwoImgContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let (data_off, data_len) = parse_header(&*reader)?;
        Ok(vec![Child {
            index: 0,
            offset: data_off,
            reader: Arc::new(SliceReader::new(Arc::clone(&reader), data_off, data_len)),
        }])
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::container::BytesReader;

    /// Build a minimal 2IMG: 64-byte header + `payload` as ProDOS-order data.
    fn sample(payload: &[u8]) -> Vec<u8> {
        let mut img = vec![0u8; 0x40];
        img[..4].copy_from_slice(MAGIC);
        img[4..8].copy_from_slice(b"QMNT");
        img[8..10].copy_from_slice(&0x40u16.to_le_bytes()); // header length
        img[0x0C..0x10].copy_from_slice(&1u32.to_le_bytes()); // ProDOS order
        img[0x14..0x18].copy_from_slice(&((payload.len() / 512) as u32).to_le_bytes());
        img[0x18..0x1C].copy_from_slice(&0x40u32.to_le_bytes()); // data offset
        img[0x1C..0x20].copy_from_slice(&(payload.len() as u32).to_le_bytes());
        img.extend_from_slice(payload);
        img
    }

    #[test]
    fn strips_header_to_one_child() {
        let payload = vec![0xABu8; 1024];
        let reader = Arc::new(BytesReader::new(sample(&payload)));
        let children = TWOIMG.children(reader).unwrap();
        assert_eq!(children.len(), 1);
        assert_eq!(children[0].offset, 0x40);

        let mut buf = [0u8; 1024];
        let n = children[0].reader.read_at(0, &mut buf).unwrap();
        assert_eq!(n, 1024);
        assert_eq!(buf[..], payload[..]);
        // The child is bounded to the payload, not the whole file.
        assert_eq!(children[0].reader.size(), Some(1024));
    }

    #[test]
    fn rejects_bad_magic() {
        let mut bad = sample(&[0u8; 512]);
        bad[0] = b'X';
        assert!(TWOIMG.children(Arc::new(BytesReader::new(bad))).is_err());
    }

    #[test]
    fn rejects_data_past_eof() {
        let mut img = sample(&[0u8; 512]);
        // Claim more data than the file holds.
        img[0x1C..0x20].copy_from_slice(&0xFFFFu32.to_le_bytes());
        assert!(TWOIMG.children(Arc::new(BytesReader::new(img))).is_err());
    }

    /// Full registry path: the `2IMG` magic rule must dispatch to this
    /// container and strip the header to exactly one raw child.
    #[test]
    fn detect_chain_strips_header() {
        let reader = Arc::new(BytesReader::new(sample(&[0u8; 1024])));
        let tree = crate::detect::detect_tree(reader);
        let node = tree
            .iter()
            .find(|n| n.format.to_str() == Ok("disk/2img"))
            .expect("disk/2img not detected");
        assert_eq!(node.children.len(), 1, "expected one raw child");
    }
}
