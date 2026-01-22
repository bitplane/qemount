//! Sun VTOC partition table reader
//!
//! Parses Sun disk labels and returns children for each data partition.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sun disk label magic at offset 508
const SUN_LABEL_MAGIC: u16 = 0xDABE;

/// Maximum partitions in Sun label
const MAX_PARTITIONS: usize = 8;

/// Sun VTOC partition table container
pub struct SunContainer;

/// Static instance for registry
pub static SUN: SunContainer = SunContainer;

impl Container for SunContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify magic at offset 508
        let magic = read_be16(&*reader, 508)?;
        if magic != SUN_LABEL_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Sun label magic not found",
            ));
        }

        // Read geometry for sector calculation
        // Offset 436: ntrks (heads), offset 438: nsect (sectors per track)
        let ntrks = read_be16(&*reader, 436)? as u64;
        let nsect = read_be16(&*reader, 438)? as u64;
        let spc = ntrks * nsect; // sectors per cylinder

        if spc == 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Invalid geometry",
            ));
        }

        let mut children = Vec::new();

        // Read partition entries at offset 444 (8 entries × 8 bytes)
        for i in 0..MAX_PARTITIONS {
            let entry_offset = 444 + (i * 8) as u64;
            let start_cyl = read_be32(&*reader, entry_offset)? as u64;
            let num_sectors = read_be32(&*reader, entry_offset + 4)? as u64;

            // Skip empty partitions
            if num_sectors == 0 {
                continue;
            }

            // Skip whole-disk partition (conventionally partition 2, index 2)
            if i == 2 {
                continue;
            }

            let start_sector = start_cyl * spc;
            let start = start_sector * 512;
            let length = num_sectors * 512;

            children.push(Child {
                index: i as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

fn read_be16(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut buf = [0u8; 2];
    if reader.read_at(offset, &mut buf)? != 2 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u16::from_be_bytes(buf))
}

fn read_be32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_be_bytes(buf))
}
