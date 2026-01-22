//! IBM DASD partition table reader
//!
//! Parses IBM mainframe DASD labels (VOL1, LNX1, CMS1) in EBCDIC encoding.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size
const SECTOR: u64 = 512;

/// Label magic values in EBCDIC (as BE32)
const VOL1_EBCDIC: u32 = 0xE5D6D3F1;
const LNX1_EBCDIC: u32 = 0xD3D5E7F1;
const CMS1_EBCDIC: u32 = 0xC3D4E2F1;

/// FMT label IDs in EBCDIC
const FMT1_EBCDIC: u8 = 0xF1; // '1' in EBCDIC
const FMT8_EBCDIC: u8 = 0xF8; // '8' in EBCDIC
const FMT4_EBCDIC: u8 = 0xF4; // '4' in EBCDIC - skip
const FMT5_EBCDIC: u8 = 0xF5; // '5' in EBCDIC - skip
const FMT7_EBCDIC: u8 = 0xF7; // '7' in EBCDIC - skip
const FMT9_EBCDIC: u8 = 0xF9; // '9' in EBCDIC - skip

/// LNX1 version with large volume support
const LNX1_VERSION_LARGE: u8 = 0xF2;

/// IBM DASD container
pub struct DasdContainer;

/// Static instance for registry
pub static DASD: DasdContainer = DasdContainer;

impl Container for DasdContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Try to find label at sector 1 or 2
        for label_sector in [1u64, 2u64] {
            let label_offset = label_sector * SECTOR;
            let magic = read_be32(&*reader, label_offset)?;

            match magic {
                VOL1_EBCDIC => return parse_vol1(&reader, label_offset),
                LNX1_EBCDIC => return parse_lnx1(&reader, label_offset, label_sector),
                CMS1_EBCDIC => return parse_cms1(&reader, label_offset, label_sector),
                _ => continue,
            }
        }

        Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "DASD label not found",
        ))
    }
}

/// Parse VOL1 (CDL) label - multiple partitions from VTOC
fn parse_vol1(
    reader: &Arc<dyn Reader + Send + Sync>,
    _label_offset: u64,
) -> io::Result<Vec<Child>> {
    // VOL1 requires parsing VTOC which needs geometry info
    // For now, return empty - full implementation would need CCHH decoding
    // and VTOC traversal which is very complex without geometry
    Ok(vec![])
}

/// Parse LNX1 (LDL) label - single partition after label
fn parse_lnx1(
    reader: &Arc<dyn Reader + Send + Sync>,
    label_offset: u64,
    label_sector: u64,
) -> io::Result<Vec<Child>> {
    // Check version byte at offset 0x0A
    let version = read_u8(&**reader, label_offset + 0x0A)?;

    let size_sectors = if version == LNX1_VERSION_LARGE {
        // Large volume: formatted_blocks at offset 0x0B (8 bytes, but usually fits in u64)
        read_be64(&**reader, label_offset + 0x0B)?
    } else {
        // Without large volume support, we can't determine size reliably
        // Return a minimal partition
        0
    };

    if size_sectors == 0 {
        return Ok(vec![]);
    }

    // Partition starts after label block (assuming 512-byte sectors)
    let start = (label_sector + 1) * SECTOR;
    let length = size_sectors * SECTOR - start;

    Ok(vec![Child {
        index: 0,
        offset: start,
        reader: Arc::new(SliceReader::new(Arc::clone(reader), start, length)),
    }])
}

/// Parse CMS1 label - single partition
fn parse_cms1(
    reader: &Arc<dyn Reader + Send + Sync>,
    label_offset: u64,
    label_sector: u64,
) -> io::Result<Vec<Child>> {
    // CMS1 structure:
    // 0x0C: block_size (BE32)
    // 0x10: disk_offset (BE32) - for minidisks
    // 0x14: block_count (BE32)
    let block_size = read_be32(&**reader, label_offset + 0x0C)?;
    let disk_offset = read_be32(&**reader, label_offset + 0x10)?;
    let block_count = read_be32(&**reader, label_offset + 0x14)?;

    if block_size == 0 || block_count == 0 {
        return Ok(vec![]);
    }

    let secperblk = block_size / 512;

    let (start, length) = if disk_offset != 0 {
        // Minidisk: offset and size from label
        let start = disk_offset as u64 * secperblk as u64 * SECTOR;
        let length = (block_count - 1) as u64 * secperblk as u64 * SECTOR;
        (start, length)
    } else {
        // Regular CMS disk
        let start = if label_sector == 1 {
            // FBA with DIAG: partition starts at block 2
            2 * secperblk as u64 * SECTOR
        } else {
            (label_sector + secperblk as u64) * SECTOR
        };
        let length = block_count as u64 * secperblk as u64 * SECTOR - start;
        (start, length)
    };

    Ok(vec![Child {
        index: 0,
        offset: start,
        reader: Arc::new(SliceReader::new(Arc::clone(reader), start, length)),
    }])
}

fn read_u8(reader: &dyn Reader, offset: u64) -> io::Result<u8> {
    let mut buf = [0u8; 1];
    if reader.read_at(offset, &mut buf)? != 1 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(buf[0])
}

fn read_be32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_be_bytes(buf))
}

fn read_be64(reader: &dyn Reader, offset: u64) -> io::Result<u64> {
    let mut buf = [0u8; 8];
    if reader.read_at(offset, &mut buf)? != 8 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u64::from_be_bytes(buf))
}
