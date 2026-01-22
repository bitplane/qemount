//! GPT (GUID Partition Table) container reader
//!
//! Parses GPT partition table and returns children for each valid partition.
//! Simpler than MBR - just a flat array of entries, no chain parsing.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size for GPT is always 512 bytes (logical sector).
/// Same as MBR - even on 4K physical sector drives, GPT LBAs use 512-byte units.
const SECTOR_SIZE: u64 = 512;

/// GPT header offset (LBA 1)
const HEADER_OFFSET: u64 = 512;

/// GPT signature
const GPT_SIGNATURE: &[u8; 8] = b"EFI PART";

/// Maximum partition entries to prevent runaway iteration
const MAX_ENTRIES: u32 = 256;

/// GPT partition table container
pub struct GptContainer;

/// Static instance for registry
pub static GPT: GptContainer = GptContainer;

impl Container for GptContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Read and verify header signature
        let mut sig = [0u8; 8];
        if reader.read_at(HEADER_OFFSET, &mut sig)? != 8 || &sig != GPT_SIGNATURE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid GPT signature",
            ));
        }

        // Read header fields
        let entries_lba = read_le64(&*reader, HEADER_OFFSET + 72)?;
        let num_entries = read_le32(&*reader, HEADER_OFFSET + 80)?;
        let entry_size = read_le32(&*reader, HEADER_OFFSET + 84)?;

        // Sanity checks
        if entry_size < 128 || num_entries > MAX_ENTRIES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid GPT header values",
            ));
        }

        let entries_offset = entries_lba * SECTOR_SIZE;
        let mut children = Vec::new();

        for i in 0..num_entries {
            let entry_offset = entries_offset + (i as u64 * entry_size as u64);

            // Check if type GUID is all zeros (unused entry)
            let mut type_guid = [0u8; 16];
            if reader.read_at(entry_offset, &mut type_guid)? != 16 {
                continue;
            }
            if type_guid == [0u8; 16] {
                continue;
            }

            // Read partition LBAs
            let first_lba = read_le64(&*reader, entry_offset + 32)?;
            let last_lba = read_le64(&*reader, entry_offset + 40)?;

            // Sanity check
            if last_lba < first_lba {
                continue;
            }

            let start = first_lba * SECTOR_SIZE;
            let length = (last_lba - first_lba + 1) * SECTOR_SIZE;

            children.push(Child {
                index: i,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
}

fn read_le32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    let n = reader.read_at(offset, &mut buf)?;
    if n != 4 {
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            "short read",
        ));
    }
    Ok(u32::from_le_bytes(buf))
}

fn read_le64(reader: &dyn Reader, offset: u64) -> io::Result<u64> {
    let mut buf = [0u8; 8];
    let n = reader.read_at(offset, &mut buf)?;
    if n != 8 {
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            "short read",
        ));
    }
    Ok(u64::from_le_bytes(buf))
}
