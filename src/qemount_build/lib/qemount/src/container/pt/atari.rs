//! Atari AHDI partition table container reader
//!
//! Parses Atari AHDI partition tables from sector 0 (rootsector).
//! Supports primary partitions, XGM extended partitions, and ICD/Supra partitions.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const SECTOR_SIZE: u64 = 512;
const PRIMARY_TABLE_OFFSET: u64 = 0x1c6;
const ICD_TABLE_OFFSET: u64 = 0x156;
const HD_SIZ_OFFSET: u64 = 0x1c2;
const MAX_XGM_CHAIN: usize = 256;

/// Valid ICD partition type IDs
const ICD_VALID_IDS: &[&[u8; 3]] = &[b"GEM", b"BGM", b"LNX", b"SWP", b"RAW"];

/// Atari AHDI partition table container
pub struct AtariContainer;

/// Static instance for registry
pub static ATARI: AtariContainer = AtariContainer;

/// Parsed partition entry
struct PartitionEntry {
    flags: u8,
    id: [u8; 3],
    start: u32,
    size: u32,
}

impl Container for AtariContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let hd_siz = read_be32(&*reader, HD_SIZ_OFFSET)?;
        let mut children = Vec::new();
        let mut partition_index = 0u32;
        let mut has_xgm = false;

        // Parse 4 primary partitions at 0x1c6
        for i in 0..4u64 {
            let entry = read_partition_entry(&*reader, PRIMARY_TABLE_OFFSET + i * 12)?;
            if !is_valid_partition(&entry, hd_siz) {
                continue;
            }

            if &entry.id == b"XGM" {
                has_xgm = true;
                // Follow XGM extended partition chain
                parse_xgm_chain(
                    &*reader,
                    &reader,
                    entry.start,
                    hd_siz,
                    &mut children,
                    &mut partition_index,
                )?;
            } else {
                add_partition(&reader, &entry, &mut children, partition_index);
                partition_index += 1;
            }
        }

        // ICD partitions only processed if no XGM extended partitions exist
        if !has_xgm {
            parse_icd_partitions(&*reader, &reader, hd_siz, &mut children, &mut partition_index)?;
        }

        Ok(children)
    }
}

/// Check if partition entry is valid per Linux kernel VALID_PARTITION macro
fn is_valid_partition(entry: &PartitionEntry, hd_siz: u32) -> bool {
    // Flag bit 0 must be set (active)
    if entry.flags & 0x01 == 0 {
        return false;
    }
    // ID must be 3 alphanumeric characters
    if !entry.id.iter().all(|&c| c.is_ascii_alphanumeric()) {
        return false;
    }
    // start must not exceed disk size
    if entry.start > hd_siz {
        return false;
    }
    // start + size must not exceed disk size
    if entry.start.saturating_add(entry.size) > hd_siz {
        return false;
    }
    true
}

/// Read partition entry at given byte offset
fn read_partition_entry(reader: &dyn Reader, offset: u64) -> io::Result<PartitionEntry> {
    let flags = read_byte(reader, offset)?;
    let mut id = [0u8; 3];
    if reader.read_at(offset + 1, &mut id)? != 3 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    let start = read_be32(reader, offset + 4)?;
    let size = read_be32(reader, offset + 8)?;
    Ok(PartitionEntry { flags, id, start, size })
}

/// Add a partition as a child
fn add_partition(
    parent: &Arc<dyn Reader + Send + Sync>,
    entry: &PartitionEntry,
    children: &mut Vec<Child>,
    index: u32,
) {
    if entry.start == 0 || entry.size == 0 {
        return;
    }
    let start = entry.start as u64 * SECTOR_SIZE;
    let length = entry.size as u64 * SECTOR_SIZE;
    children.push(Child {
        index,
        offset: start,
        reader: Arc::new(SliceReader::new(Arc::clone(parent), start, length)),
    });
}

/// Parse XGM extended partition chain
fn parse_xgm_chain(
    reader: &dyn Reader,
    parent: &Arc<dyn Reader + Send + Sync>,
    xgm_start: u32,
    hd_siz: u32,
    children: &mut Vec<Child>,
    partition_index: &mut u32,
) -> io::Result<()> {
    let extension_sect = xgm_start as u64; // Original XGM start for chain offsets
    let mut current_sect = xgm_start as u64;

    for _ in 0..MAX_XGM_CHAIN {
        let base = current_sect * SECTOR_SIZE;

        // Read partition entries from XGM sector (same layout as rootsector)
        let entry0 = read_partition_entry(reader, base + PRIMARY_TABLE_OFFSET)?;
        let entry1 = read_partition_entry(reader, base + PRIMARY_TABLE_OFFSET + 12)?;

        // Entry 0: actual partition (start relative to THIS XGM sector)
        if entry0.flags & 0x01 != 0 && entry0.start > 0 && entry0.size > 0 {
            let abs_start = current_sect + entry0.start as u64;
            if abs_start + entry0.size as u64 <= hd_siz as u64 {
                let start_bytes = abs_start * SECTOR_SIZE;
                let length = entry0.size as u64 * SECTOR_SIZE;
                children.push(Child {
                    index: *partition_index,
                    offset: start_bytes,
                    reader: Arc::new(SliceReader::new(Arc::clone(parent), start_bytes, length)),
                });
                *partition_index += 1;
            }
        }

        // Entry 1: next XGM link (start relative to ORIGINAL XGM start)
        // Chain ends when entry 1's ID is not "XGM"
        if &entry1.id != b"XGM" || entry1.start == 0 {
            break;
        }

        let next_sect = extension_sect + entry1.start as u64;
        // Prevent infinite loops
        if next_sect <= current_sect || next_sect >= hd_siz as u64 {
            break;
        }
        current_sect = next_sect;
    }

    Ok(())
}

/// Parse ICD/Supra partitions at offset 0x156
fn parse_icd_partitions(
    reader: &dyn Reader,
    parent: &Arc<dyn Reader + Send + Sync>,
    hd_siz: u32,
    children: &mut Vec<Child>,
    partition_index: &mut u32,
) -> io::Result<()> {
    // Check if first ICD partition has a valid type ID
    let first_entry = read_partition_entry(reader, ICD_TABLE_OFFSET)?;
    if !ICD_VALID_IDS.iter().any(|&valid| &first_entry.id == valid) {
        return Ok(());
    }

    // Process up to 8 ICD partitions
    for i in 0..8u64 {
        let entry = read_partition_entry(reader, ICD_TABLE_OFFSET + i * 12)?;
        if !is_valid_partition(&entry, hd_siz) {
            continue;
        }
        add_partition(parent, &entry, children, *partition_index);
        *partition_index += 1;
    }

    Ok(())
}

fn read_byte(reader: &dyn Reader, offset: u64) -> io::Result<u8> {
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
