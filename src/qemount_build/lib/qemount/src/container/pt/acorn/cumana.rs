//! Cumana SCSI partition table container
//!
//! Cumana SCSI controller partition format. Boot block at sector 6.
//! Uses ADFS format but chains to additional partitions via pointers.
//! Partition type at byte 0x1fc, next cylinder at 0x1fd-0x1fe.

use super::{
    adfs_checksum, read_le32, read_sector, DiscRecord, LINUX_NATIVE_MAGIC, LINUX_SWAP_MAGIC,
    PARTITION_LINUX, PARTITION_RISCIX_MFM, PARTITION_RISCIX_SCSI, RISCIX_MAGIC, SECTOR_SIZE,
};
use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Cumana partition table container
pub struct CumanaContainer;

/// Static instance for registry
pub static CUMANA: CumanaContainer = CumanaContainer;

/// Maximum chain length to prevent infinite loops
const MAX_CHAIN: usize = 64;

impl Container for CumanaContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let mut children = Vec::new();
        let mut slot = 0u32;
        let mut start_blk: u64 = 0;
        let mut first_sector: u64 = 0;

        for _ in 0..MAX_CHAIN {
            // Read boot block at start_blk * 2 + 6
            // (Cumana uses 1K blocks, sector 6 within first block)
            let sector_num = start_blk * 2 + 6;
            let boot = match read_sector(&*reader, sector_num) {
                Ok(s) => s,
                Err(_) => break,
            };

            // Validate checksum
            if !adfs_checksum(&boot) {
                break;
            }

            // Parse disc record
            let dr = match DiscRecord::parse(&boot) {
                Some(d) => d,
                None => break,
            };

            // Check disc has non-zero size
            if dr.disc_size == 0 && dr.disc_size_high == 0 {
                break;
            }

            // Add ADFS partition
            let nr_sects = dr.sectors();
            if nr_sects > 0 {
                let start = first_sector * SECTOR_SIZE;
                let length = nr_sects * SECTOR_SIZE;
                children.push(Child {
                    index: slot,
                    offset: start,
                    reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
                });
                slot += 1;
            }

            // Calculate next partition location
            let heads = dr.effective_heads();
            let sectscyl = dr.secspertrack as u64 * heads;
            let cylinder = (boot[0x1fe] as u64) << 8 | boot[0x1fd] as u64;
            let next_sects = cylinder * sectscyl;

            if next_sects == 0 {
                break;
            }

            first_sector += next_sects;
            start_blk += next_sects >> 1; // Convert sectors to 1K blocks

            // Check partition type
            let part_type = boot[0x1fc] & 0x0f;

            match part_type {
                0 => {
                    // Continue to next ADFS partition
                    continue;
                }
                PARTITION_RISCIX_MFM | PARTITION_RISCIX_SCSI => {
                    // RISCiX partition - we don't know how to find the next one
                    parse_riscix_cumana(&reader, first_sector, &mut children, &mut slot)?;
                    break;
                }
                PARTITION_LINUX => {
                    // Linux partition
                    parse_linux_cumana(&reader, first_sector, &mut children, &mut slot)?;
                    break;
                }
                _ => {
                    break;
                }
            }
        }

        Ok(children)
    }
}

/// Parse RISCiX partition within Cumana chain
fn parse_riscix_cumana(
    reader: &Arc<dyn Reader + Send + Sync>,
    start_sect: u64,
    children: &mut Vec<Child>,
    slot: &mut u32,
) -> io::Result<()> {
    let sector = read_sector(&**reader, start_sect)?;

    // First allocate boot area (2 sectors)
    let start = start_sect * SECTOR_SIZE;
    let boot_size = 2 * SECTOR_SIZE;
    children.push(Child {
        index: *slot,
        offset: start,
        reader: Arc::new(SliceReader::new(Arc::clone(reader), start, boot_size)),
    });
    *slot += 1;

    // Check RISCiX magic
    let magic = read_le32(&sector, 0);
    if magic != RISCIX_MAGIC {
        return Ok(());
    }

    // Parse 8 partition entries
    for i in 0..8 {
        let entry_off = 8 + i * 28;
        let part_start = read_le32(&sector, entry_off);
        let length = read_le32(&sector, entry_off + 4);
        let one = read_le32(&sector, entry_off + 8);
        let name = &sector[entry_off + 12..entry_off + 28];

        if one == 0 || name.starts_with(b"All\0") {
            continue;
        }

        if part_start > 0 && length > 0 {
            let start_bytes = part_start as u64 * SECTOR_SIZE;
            let length_bytes = length as u64 * SECTOR_SIZE;
            children.push(Child {
                index: *slot,
                offset: start_bytes,
                reader: Arc::new(SliceReader::new(Arc::clone(reader), start_bytes, length_bytes)),
            });
            *slot += 1;
        }
    }

    Ok(())
}

/// Parse Linux partition within Cumana chain
fn parse_linux_cumana(
    reader: &Arc<dyn Reader + Send + Sync>,
    start_sect: u64,
    children: &mut Vec<Child>,
    slot: &mut u32,
) -> io::Result<()> {
    let sector = read_sector(&**reader, start_sect)?;

    // First allocate boot area (2 sectors)
    let start = start_sect * SECTOR_SIZE;
    let boot_size = 2 * SECTOR_SIZE;
    children.push(Child {
        index: *slot,
        offset: start,
        reader: Arc::new(SliceReader::new(Arc::clone(reader), start, boot_size)),
    });
    *slot += 1;

    // Parse Linux partition entries
    let mut offset = 0usize;
    loop {
        if offset + 12 > 512 {
            break;
        }
        let magic = read_le32(&sector, offset);
        if magic != LINUX_NATIVE_MAGIC && magic != LINUX_SWAP_MAGIC {
            break;
        }

        let part_start = read_le32(&sector, offset + 4);
        let part_size = read_le32(&sector, offset + 8);

        if part_start > 0 && part_size > 0 {
            let abs_start = (start_sect + part_start as u64) * SECTOR_SIZE;
            let length = part_size as u64 * SECTOR_SIZE;
            children.push(Child {
                index: *slot,
                offset: abs_start,
                reader: Arc::new(SliceReader::new(Arc::clone(reader), abs_start, length)),
            });
            *slot += 1;
        }

        offset += 12;
    }

    Ok(())
}
