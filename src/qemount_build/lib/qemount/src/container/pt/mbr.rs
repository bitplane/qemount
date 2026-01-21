//! MBR partition table container reader
//!
//! Parses MBR partition table and returns children for each valid partition.
//! Handles extended partitions (EBR chain) for types 0x05 and 0x0F.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size for MBR is always 512 bytes (logical sector).
/// Even on 4K physical sector drives, MBR LBAs use 512-byte units.
/// The firmware/OS handles translation to physical sectors.
const SECTOR_SIZE: u64 = 512;

/// Partition table offset within MBR/EBR
const PARTITION_TABLE_OFFSET: u64 = 446;

/// Boot signature
const BOOT_SIG: u16 = 0xAA55;

/// Partition types to skip
const TYPE_EMPTY: u8 = 0x00;
const TYPE_GPT_PROTECTIVE: u8 = 0xEE;

/// Extended partition types
const TYPE_EXTENDED_CHS: u8 = 0x05;
const TYPE_EXTENDED_LBA: u8 = 0x0F;

/// Maximum logical partitions to prevent infinite loops
const MAX_LOGICAL: usize = 256;

/// MBR partition table container
pub struct MbrContainer;

/// Static instance for registry
pub static MBR: MbrContainer = MbrContainer;

/// Parsed partition entry
#[derive(Clone, Copy)]
struct PartitionEntry {
    type_code: u8,
    lba_start: u32,
    sector_count: u32,
}

/// First logical partition index (after the 4 primary slots)
const FIRST_LOGICAL_INDEX: u32 = 4;

impl Container for MbrContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let mut children = Vec::new();
        let mut logical_index: u32 = FIRST_LOGICAL_INDEX;

        let entries = read_partition_table(&*reader, 0)?;

        for (slot, entry) in entries.iter().enumerate() {
            if entry.type_code == TYPE_EMPTY || entry.type_code == TYPE_GPT_PROTECTIVE {
                continue;
            }

            if entry.type_code == TYPE_EXTENDED_CHS || entry.type_code == TYPE_EXTENDED_LBA {
                let extended_start = entry.lba_start as u64;
                let extended_size = entry.sector_count as u64;
                let logical = parse_extended_chain(
                    &*reader,
                    &reader,
                    extended_start,
                    extended_size,
                    &mut logical_index,
                )?;
                children.extend(logical);
            } else {
                let offset = entry.lba_start as u64 * SECTOR_SIZE;
                let length = entry.sector_count as u64 * SECTOR_SIZE;
                if entry.lba_start > 0 && entry.sector_count > 0 {
                    // Primary partitions use their slot index (0-3)
                    children.push(Child {
                        index: slot as u32,
                        reader: Arc::new(SliceReader::new(Arc::clone(&reader), offset, length)),
                    });
                }
            }
        }

        Ok(children)
    }
}

/// Read partition table at given LBA
fn read_partition_table(reader: &dyn Reader, lba: u64) -> io::Result<[PartitionEntry; 4]> {
    let base = lba * SECTOR_SIZE;

    let sig = read_le16(reader, base + 510)?;
    if sig != BOOT_SIG {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "invalid boot signature",
        ));
    }

    let mut entries = [PartitionEntry {
        type_code: 0,
        lba_start: 0,
        sector_count: 0,
    }; 4];

    for i in 0..4 {
        let entry_offset = base + PARTITION_TABLE_OFFSET + (i as u64 * 16);
        entries[i] = PartitionEntry {
            type_code: read_byte(reader, entry_offset + 4)?,
            lba_start: read_le32(reader, entry_offset + 8)?,
            sector_count: read_le32(reader, entry_offset + 12)?,
        };
    }

    Ok(entries)
}

/// Parse extended partition chain (EBR linked list)
fn parse_extended_chain(
    reader: &dyn Reader,
    parent: &Arc<dyn Reader + Send + Sync>,
    extended_start: u64,
    extended_size: u64,
    partition_index: &mut u32,
) -> io::Result<Vec<Child>> {
    let mut children = Vec::new();
    let mut current_ebr_lba = extended_start;

    for _ in 0..MAX_LOGICAL {
        let entries = match read_partition_table(reader, current_ebr_lba) {
            Ok(e) => e,
            Err(_) => break,
        };

        // Entry 0: logical partition (LBA relative to THIS EBR)
        let logical = &entries[0];
        if logical.type_code != TYPE_EMPTY && logical.lba_start > 0 && logical.sector_count > 0 {
            let partition_lba = current_ebr_lba + logical.lba_start as u64;
            let partition_end_lba = partition_lba + logical.sector_count as u64;

            // Sanity check: partition should be within extended partition
            if partition_end_lba <= extended_start + extended_size {
                let offset = partition_lba * SECTOR_SIZE;
                let length = logical.sector_count as u64 * SECTOR_SIZE;
                children.push(Child {
                    index: *partition_index,
                    reader: Arc::new(SliceReader::new(Arc::clone(parent), offset, length)),
                });
                *partition_index += 1;
            }
        }

        // Entry 1: next EBR (LBA relative to EXTENDED partition start)
        let next_ebr = &entries[1];
        if next_ebr.type_code == TYPE_EMPTY || next_ebr.lba_start == 0 {
            break;
        }

        let next_lba = extended_start + next_ebr.lba_start as u64;

        // Sanity check: next EBR should be within extended partition
        if next_lba >= extended_start + extended_size {
            break;
        }

        // Sanity check: must move forward to prevent infinite loop
        if next_lba <= current_ebr_lba {
            break;
        }

        current_ebr_lba = next_lba;
    }

    Ok(children)
}

fn read_byte(reader: &dyn Reader, offset: u64) -> io::Result<u8> {
    let mut buf = [0u8; 1];
    let n = reader.read_at(offset, &mut buf)?;
    if n != 1 {
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            "short read",
        ));
    }
    Ok(buf[0])
}

fn read_le16(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut buf = [0u8; 2];
    let n = reader.read_at(offset, &mut buf)?;
    if n != 2 {
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            "short read",
        ));
    }
    Ok(u16::from_le_bytes(buf))
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
