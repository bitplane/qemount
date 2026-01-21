//! BSD disklabel container reader
//!
//! Parses BSD disklabel partition table and returns children for each partition.
//! Supports both offset 0 and offset 512 (within MBR partition) layouts.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// BSD disklabel magic number (little-endian)
const DISKLABEL_MAGIC: u32 = 0x82564557;

/// Maximum partitions to process
const MAX_PARTITIONS: usize = 22;

/// Filesystem type: unused partition
const FS_UNUSED: u8 = 0;

/// BSD disklabel container
pub struct DisklabelContainer;

/// Static instance for registry
pub static DISKLABEL: DisklabelContainer = DisklabelContainer;

impl Container for DisklabelContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Try offset 0 first, then 512 (embedded in MBR)
        let base = find_disklabel(&*reader)?;

        // Verify both magic numbers
        let magic1 = read_le32(&*reader, base)?;
        let magic2 = read_le32(&*reader, base + 132)?;
        if magic1 != DISKLABEL_MAGIC || magic2 != DISKLABEL_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "disklabel magic mismatch",
            ));
        }

        let sector_size = read_le32(&*reader, base + 40)? as u64;
        let npartitions = read_le16(&*reader, base + 138)? as usize;
        let npartitions = npartitions.min(MAX_PARTITIONS);

        let mut children = Vec::new();

        for i in 0..npartitions {
            let entry_offset = base + 148 + (i as u64 * 16);

            let size_sectors = read_le32(&*reader, entry_offset)?;
            let offset_sectors = read_le32(&*reader, entry_offset + 4)?;
            let fstype = read_byte(&*reader, entry_offset + 12)?;

            // Skip unused partitions and partition 'c' (whole disk, index 2)
            if fstype == FS_UNUSED || size_sectors == 0 || i == 2 {
                continue;
            }

            let start = offset_sectors as u64 * sector_size;
            let length = size_sectors as u64 * sector_size;

            children.push(Child {
                index: i as u32,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

/// Find disklabel offset (0 or 512)
fn find_disklabel(reader: &dyn Reader) -> io::Result<u64> {
    // Try offset 0
    if let Ok(magic) = read_le32(reader, 0) {
        if magic == DISKLABEL_MAGIC {
            return Ok(0);
        }
    }

    // Try offset 512 (within MBR partition)
    if let Ok(magic) = read_le32(reader, 512) {
        if magic == DISKLABEL_MAGIC {
            return Ok(512);
        }
    }

    Err(io::Error::new(
        io::ErrorKind::InvalidData,
        "disklabel magic not found",
    ))
}

fn read_byte(reader: &dyn Reader, offset: u64) -> io::Result<u8> {
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
