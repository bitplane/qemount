//! Rio Karma partition table reader
//!
//! Parses Rio Karma disklabel and returns children for each valid partition.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size
const SECTOR: u64 = 512;

/// Magic value at offset 510
const KARMA_MAGIC: u16 = 0xAB56;

/// Partition table offset (after 270 reserved bytes)
const PARTITION_OFFSET: u64 = 270;

/// Valid filesystem type
const FSTYPE_VALID: u8 = 0x4D;

/// Rio Karma container
pub struct KarmaContainer;

/// Static instance for registry
pub static KARMA: KarmaContainer = KarmaContainer;

impl Container for KarmaContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify magic at offset 510
        let magic = read_le16(&*reader, 510)?;
        if magic != KARMA_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Karma magic not found",
            ));
        }

        let mut children = Vec::new();

        // Read 2 partition entries (16 bytes each)
        for i in 0..2 {
            let entry_offset = PARTITION_OFFSET + (i * 16) as u64;

            let fstype = read_u8(&*reader, entry_offset + 4)?;
            let start_sector = read_le32(&*reader, entry_offset + 8)?;
            let size_sectors = read_le32(&*reader, entry_offset + 12)?;

            // Only include if fstype == 0x4D and size > 0
            if fstype != FSTYPE_VALID || size_sectors == 0 {
                continue;
            }

            let start = start_sector as u64 * SECTOR;
            let length = size_sectors as u64 * SECTOR;

            children.push(Child {
                index: i as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

fn read_u8(reader: &dyn Reader, offset: u64) -> io::Result<u8> {
    let mut buf = [0u8; 1];
    if reader.read_at(offset, &mut buf)? != 1 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(buf[0])
}

fn read_le16(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut buf = [0u8; 2];
    if reader.read_at(offset, &mut buf)? != 2 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u16::from_le_bytes(buf))
}

fn read_le32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_le_bytes(buf))
}
