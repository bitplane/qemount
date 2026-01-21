//! RDB (Amiga Rigid Disk Block) container reader
//!
//! Parses Amiga RDB partition table and returns children for each partition.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// RDB signature "RDSK"
const RDB_SIGNATURE: &[u8; 4] = b"RDSK";

/// Partition block signature "PART"
const PART_SIGNATURE: &[u8; 4] = b"PART";

/// End-of-list marker
const NO_BLOCK: u32 = 0xFFFFFFFF;

/// Maximum blocks to search for RDSK header
const MAX_RDB_SEARCH: u32 = 16;

/// Maximum partitions to prevent runaway iteration
const MAX_PARTITIONS: u32 = 256;

/// RDB partition table container
pub struct RdbContainer;

/// Static instance for registry
pub static RDB: RdbContainer = RdbContainer;

impl Container for RdbContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Search for RDSK in first 16 blocks (assuming 512-byte blocks initially)
        let mut rdb_offset = None;
        let mut sig = [0u8; 4];

        for blk in 0..MAX_RDB_SEARCH {
            let offset = blk as u64 * 512;
            if reader.read_at(offset, &mut sig)? != 4 {
                break;
            }
            if &sig == RDB_SIGNATURE {
                rdb_offset = Some(offset);
                break;
            }
        }

        let rdb_offset = rdb_offset.ok_or_else(|| {
            io::Error::new(io::ErrorKind::InvalidData, "RDSK signature not found")
        })?;

        // Read RDB header - all values are big-endian
        let block_size = read_be32(&*reader, rdb_offset + 16)? as u64;
        let part_list = read_be32(&*reader, rdb_offset + 28)?;
        let cyl_blks = read_be32(&*reader, rdb_offset + 144)? as u64;

        // Follow partition linked list
        let mut children = Vec::new();
        let mut part_blk = part_list;

        while part_blk != NO_BLOCK && children.len() < MAX_PARTITIONS as usize {
            let part_offset = part_blk as u64 * block_size;

            // Verify PART signature
            if reader.read_at(part_offset, &mut sig)? != 4 || &sig != PART_SIGNATURE {
                break;
            }

            let next = read_be32(&*reader, part_offset + 16)?;
            let low_cyl = read_be32(&*reader, part_offset + 164)? as u64;
            let high_cyl = read_be32(&*reader, part_offset + 168)? as u64;

            let start = low_cyl * cyl_blks * block_size;
            let length = (high_cyl - low_cyl + 1) * cyl_blks * block_size;

            children.push(Child {
                index: children.len() as u32,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });

            part_blk = next;
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
