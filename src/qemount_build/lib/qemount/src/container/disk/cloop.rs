//! cloop (Compressed Loop) disk image reader
//!
//! Parses cloop format used for live CD distributions like Knoppix.
//! Blocks are zlib compressed with an offset table for random access.

use crate::container::{checked_table_size, invalid_data, Child, Container};
use crate::detect::Reader;
use flate2::read::ZlibDecoder;
use std::io::{self, Read};
use std::sync::Arc;

const HEADER_OFFSET: u64 = 128; // After optional shell script header
const MAX_BLOCK_SIZE: u32 = 64 * 1024 * 1024; // 64 MB

/// cloop disk image container
pub struct CloopContainer;

/// Static instance for registry
pub static CLOOP: CloopContainer = CloopContainer;

impl Container for CloopContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let cloop_reader = CloopReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(cloop_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through cloop block table
pub struct CloopReader {
    parent: Arc<dyn Reader + Send + Sync>,
    offsets: Vec<u64>,
    block_size: u64,
    virtual_size: u64,
}

impl CloopReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header at offset 128
        let mut header = [0u8; 8];
        if parent.read_at(HEADER_OFFSET, &mut header)? != 8 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short cloop header read",
            ));
        }

        // Parse header (big-endian)
        let block_size = u32::from_be_bytes([header[0], header[1], header[2], header[3]]);
        let n_blocks = u32::from_be_bytes([header[4], header[5], header[6], header[7]]);

        // Validate block_size
        if block_size == 0 || block_size > MAX_BLOCK_SIZE || block_size % 512 != 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid cloop block_size",
            ));
        }

        // Read offset table (n_blocks + 1 entries, 8 bytes each)
        let table_entries = (n_blocks as u64)
            .checked_add(1)
            .ok_or_else(|| invalid_data("cloop table size overflow"))?;
        let table_offset = HEADER_OFFSET + 8;
        let table_bytes = checked_table_size(parent.as_ref(), table_offset, table_entries, 8)?;
        let mut table_data = vec![0u8; table_bytes];

        if parent.read_at(table_offset, &mut table_data)? != table_bytes {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short cloop offset table read",
            ));
        }

        // Parse offset table (big-endian u64)
        let offsets: Vec<u64> = table_data
            .chunks_exact(8)
            .map(|chunk| {
                u64::from_be_bytes([
                    chunk[0], chunk[1], chunk[2], chunk[3],
                    chunk[4], chunk[5], chunk[6], chunk[7],
                ])
            })
            .collect();

        let table_end = table_offset + table_bytes as u64;
        let image_size = parent.size();
        if offsets.first().is_some_and(|&offset| offset < table_end)
            || offsets.windows(2).any(|pair| pair[0] > pair[1])
            || image_size.is_some_and(|size| offsets.last().is_some_and(|&offset| offset > size))
        {
            return Err(invalid_data("invalid cloop block offsets"));
        }

        let virtual_size = n_blocks as u64 * block_size as u64;

        Ok(Self {
            parent,
            offsets,
            block_size: block_size as u64,
            virtual_size,
        })
    }

    fn decompress_block(&self, block_idx: usize) -> io::Result<Vec<u8>> {
        if block_idx + 1 >= self.offsets.len() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "block index out of range",
            ));
        }

        let start = self.offsets[block_idx];
        let end = self.offsets[block_idx + 1];
        let compressed_size = end
            .checked_sub(start)
            .and_then(|size| usize::try_from(size).ok())
            .filter(|&size| size <= zlib_bound(self.block_size as usize))
            .ok_or_else(|| invalid_data("invalid cloop compressed block size"))?;

        // Read compressed data
        let mut compressed = vec![0u8; compressed_size];
        if self.parent.read_at(start, &mut compressed)? != compressed_size {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short cloop block read",
            ));
        }

        // Decompress with zlib
        let mut decoder = ZlibDecoder::new(&compressed[..]);
        let mut decompressed = vec![0u8; self.block_size as usize];
        decoder.read_exact(&mut decompressed)?;

        Ok(decompressed)
    }
}

impl Reader for CloopReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        let block_idx = (offset / self.block_size) as usize;
        let in_block = (offset % self.block_size) as usize;

        // How much can we read from this block?
        let remaining_in_block = self.block_size as usize - in_block;
        let remaining_in_disk = (self.virtual_size - offset) as usize;
        let to_read = buf.len().min(remaining_in_block).min(remaining_in_disk);

        // Decompress block and extract data
        let decompressed = self.decompress_block(block_idx)?;
        buf[..to_read].copy_from_slice(&decompressed[in_block..][..to_read]);

        Ok(to_read)
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: CloopReader only holds Arc and Vec, safe to send/share
unsafe impl Send for CloopReader {}
unsafe impl Sync for CloopReader {}

fn zlib_bound(size: usize) -> usize {
    size + (size >> 12) + (size >> 14) + (size >> 25) + 13
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::container::BytesReader;

    fn image(offsets: &[u64]) -> Vec<u8> {
        let mut data = vec![0u8; HEADER_OFFSET as usize];
        data.extend_from_slice(&512u32.to_be_bytes());
        data.extend_from_slice(&((offsets.len() - 1) as u32).to_be_bytes());
        for offset in offsets {
            data.extend_from_slice(&offset.to_be_bytes());
        }
        data
    }

    #[test]
    fn rejects_table_larger_than_image() {
        let mut data = image(&[144]);
        data[132..136].copy_from_slice(&u32::MAX.to_be_bytes());
        assert!(CloopReader::new(Arc::new(BytesReader::new(data))).is_err());
    }

    #[test]
    fn rejects_descending_block_offsets() {
        let data = image(&[152, 151]);
        assert!(CloopReader::new(Arc::new(BytesReader::new(data))).is_err());
    }
}
