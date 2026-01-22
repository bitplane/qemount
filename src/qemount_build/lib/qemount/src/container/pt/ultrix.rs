//! Ultrix partition table reader
//!
//! Parses DEC Ultrix disklabels and returns children for each partition.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size
const SECTOR: u64 = 512;

/// Disklabel offset (16384 - 72)
const LABEL_OFFSET: u64 = 16312;

/// Magic value
const PT_MAGIC: u32 = 0x032957;

/// Valid flag
const PT_VALID: u32 = 1;

/// Maximum partitions
const MAX_PARTITIONS: usize = 8;

/// Ultrix container
pub struct UltrixContainer;

/// Static instance for registry
pub static ULTRIX: UltrixContainer = UltrixContainer;

impl Container for UltrixContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify magic and valid flag
        let magic = read_le32(&*reader, LABEL_OFFSET)?;
        let valid = read_le32(&*reader, LABEL_OFFSET + 4)?;

        if magic != PT_MAGIC || valid != PT_VALID {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Ultrix disklabel not found",
            ));
        }

        let mut children = Vec::new();

        // Read 8 partition entries starting at offset +8
        let table_offset = LABEL_OFFSET + 8;
        for i in 0..MAX_PARTITIONS {
            let entry_offset = table_offset + (i * 8) as u64;
            let nblocks = read_le32(&*reader, entry_offset)?;
            let blkoff = read_le32(&*reader, entry_offset + 4)?;

            if nblocks == 0 {
                continue;
            }

            let start = blkoff as u64 * SECTOR;
            let length = nblocks as u64 * SECTOR;

            children.push(Child {
                index: i as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

fn read_le32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_le_bytes(buf))
}
