//! PC-98 partition table reader
//!
//! Parses NEC PC-98 disk labels and returns children for each partition.
//! Based on Linux kernel fs/partitions/nec98.c

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// PC-98 magic at offset 510
const PC98_MAGIC: u16 = 0xAA55;

/// Maximum partitions in PC-98
const MAX_PARTITIONS: usize = 16;

/// Partition table starts at sector 1 (offset 512)
const PARTITION_TABLE_OFFSET: u64 = 512;

/// PC-98 geometry (parted's default for images)
const HEADS: u64 = 8;
const SECTORS_PER_TRACK: u64 = 16;

/// PC-98 partition table container
pub struct Pc98Container;

/// Static instance for registry
pub static PC98: Pc98Container = Pc98Container;

impl Container for Pc98Container {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify magic at offset 510
        let magic = read_le16(&*reader, 510)?;
        if magic != PC98_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "PC-98 magic not found",
            ));
        }

        let mut children = Vec::new();

        for i in 0..MAX_PARTITIONS {
            let entry_offset = PARTITION_TABLE_OFFSET + (i * 32) as u64;

            let mut buf = [0u8; 32];
            if reader.read_at(entry_offset, &mut buf)? != 32 {
                continue;
            }

            let mid = buf[0];
            let sid = buf[1];

            // Skip empty entries (Linux kernel: if mid == 0 || sid == 0)
            if mid == 0 || sid == 0 {
                continue;
            }

            // Parse CHS values (little-endian, 0-indexed sectors)
            let sector = buf[8] as u64;
            let head = buf[9] as u64;
            let cyl = u16::from_le_bytes([buf[10], buf[11]]) as u64;
            let end_cyl = u16::from_le_bytes([buf[14], buf[15]]) as u64;

            // Linux kernel formula:
            // start_sect = (cyl * heads + head) * sectors + sector
            // end_sect = (end_cyl + 1) * heads * sectors
            let start_sect = (cyl * HEADS + head) * SECTORS_PER_TRACK + sector;
            let end_sect = (end_cyl + 1) * HEADS * SECTORS_PER_TRACK;

            if end_sect <= start_sect {
                continue;
            }

            let start = start_sect * 512;
            let length = (end_sect - start_sect) * 512;

            children.push(Child {
                index: i as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

fn read_le16(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut buf = [0u8; 2];
    if reader.read_at(offset, &mut buf)? != 2 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u16::from_le_bytes(buf))
}
