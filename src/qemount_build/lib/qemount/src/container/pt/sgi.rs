//! SGI DVH (Disk Volume Header) partition table reader
//!
//! Parses SGI disk volume headers and returns children for each data partition.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// SGI DVH magic at offset 0
const SGI_LABEL_MAGIC: u32 = 0x0BE5A941;

/// Maximum partitions in SGI DVH
const MAX_PARTITIONS: usize = 16;

/// Partition table starts at offset 312 (0x138)
const PARTITION_TABLE_OFFSET: u64 = 312;

/// Partition types to skip
const PT_VOLHDR: u32 = 0; // Volume header
const PT_VOLUME: u32 = 6; // Entire volume (whole disk)

/// SGI DVH partition table container
pub struct SgiContainer;

/// Static instance for registry
pub static SGI: SgiContainer = SgiContainer;

impl Container for SgiContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify magic at offset 0
        let magic = read_be32(&*reader, 0)?;
        if magic != SGI_LABEL_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "SGI DVH magic not found",
            ));
        }

        let mut children = Vec::new();

        // Read partition entries at offset 352 (16 entries × 12 bytes)
        for i in 0..MAX_PARTITIONS {
            let entry_offset = PARTITION_TABLE_OFFSET + (i * 12) as u64;
            let num_blocks = read_be32(&*reader, entry_offset)?;
            let first_block = read_be32(&*reader, entry_offset + 4)?;
            let ptype = read_be32(&*reader, entry_offset + 8)?;

            // Skip empty or special partitions
            if num_blocks == 0 || ptype == PT_VOLHDR || ptype == PT_VOLUME {
                continue;
            }

            let start = first_block as u64 * 512;
            let length = num_blocks as u64 * 512;

            children.push(Child {
                index: i as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

fn read_be32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_be_bytes(buf))
}
