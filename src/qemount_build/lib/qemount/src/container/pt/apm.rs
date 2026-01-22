//! APM (Apple Partition Map) container reader
//!
//! Parses Apple Partition Map and returns children for each data partition.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Driver Descriptor Map signature "ER"
const DDM_SIGNATURE: u16 = 0x4552;

/// Partition Map entry signature "PM"
const PM_SIGNATURE: u16 = 0x504D;

/// Maximum partitions to prevent runaway iteration
const MAX_PARTITIONS: u32 = 64;

/// APM partition table container
pub struct ApmContainer;

/// Static instance for registry
pub static APM: ApmContainer = ApmContainer;

impl Container for ApmContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Verify DDM signature at block 0
        let ddm_sig = read_be16(&*reader, 0)?;
        if ddm_sig != DDM_SIGNATURE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "DDM signature not found",
            ));
        }

        let block_size = read_be16(&*reader, 2)? as u64;

        // Read first partition entry to get map count
        let pm_sig = read_be16(&*reader, block_size)?;
        if pm_sig != PM_SIGNATURE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "PM signature not found",
            ));
        }

        let map_entries = read_be32(&*reader, block_size + 4)?;
        let map_entries = map_entries.min(MAX_PARTITIONS);

        let mut children = Vec::new();

        // Iterate through partition entries
        for i in 1..=map_entries {
            let entry_offset = i as u64 * block_size;

            let sig = read_be16(&*reader, entry_offset)?;
            if sig != PM_SIGNATURE {
                break;
            }

            let pblock_start = read_be32(&*reader, entry_offset + 8)? as u64;
            let pblock_count = read_be32(&*reader, entry_offset + 12)? as u64;

            // Read partition type to skip map/driver partitions
            let mut ptype = [0u8; 32];
            reader.read_at(entry_offset + 48, &mut ptype)?;
            let ptype_str = std::str::from_utf8(&ptype)
                .unwrap_or("")
                .trim_end_matches('\0');

            // Skip partition map and driver partitions
            if ptype_str == "Apple_partition_map"
                || ptype_str.starts_with("Apple_Driver")
                || ptype_str == "Apple_Free"
            {
                continue;
            }

            let start = pblock_start * block_size;
            let length = pblock_count * block_size;

            children.push(Child {
                index: children.len() as u32,
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
