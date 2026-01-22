//! SYSV68 (Motorola 68k System V) partition table reader
//!
//! Parses SYSV68 disk labels and returns children for each slice.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size
const SECTOR: u64 = 512;

/// Magic string at offset 248
const MOTOROLA_MAGIC: &[u8; 8] = b"MOTOROLA";

/// SYSV68 container
pub struct Sysv68Container;

/// Static instance for registry
pub static SYSV68: Sysv68Container = Sysv68Container;

impl Container for Sysv68Container {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify magic at offset 248
        let mut magic = [0u8; 8];
        if reader.read_at(248, &mut magic)? != 8 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
        }
        if &magic != MOTOROLA_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "MOTOROLA magic not found",
            ));
        }

        // Read slice table location and count from dkconfig
        // ios_slcblk at offset 0x180 (384), ios_slccnt at offset 0x184 (388)
        let slc_blk = read_be32(&*reader, 0x180)? as u64;
        let slc_cnt = read_be16(&*reader, 0x184)? as usize;

        if slc_blk == 0 || slc_cnt == 0 {
            return Ok(vec![]);
        }

        // Last slice is whole disk, skip it
        let slices = slc_cnt.saturating_sub(1);

        let mut children = Vec::new();

        // Read slice table
        let table_offset = slc_blk * SECTOR;
        for i in 0..slices {
            let entry_offset = table_offset + (i * 8) as u64;
            let nblocks = read_be32(&*reader, entry_offset)?;
            let blkoff = read_be32(&*reader, entry_offset + 4)?;

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
