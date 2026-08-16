//! ADFS partition table container
//!
//! Native Acorn partition format. Boot block at sector 6.
//! May contain secondary partition (RISCiX or Linux) after primary ADFS.

use super::{
    adfs_checksum, read_le32, read_sector, DiscRecord, LINUX_NATIVE_MAGIC, LINUX_SWAP_MAGIC,
    PARTITION_LINUX, PARTITION_RISCIX_MFM, PARTITION_RISCIX_SCSI, RISCIX_MAGIC, SECTOR_SIZE,
};
use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// ADFS partition table container
pub struct AdfsContainer;

/// Static instance for registry
pub static ADFS: AdfsContainer = AdfsContainer;

impl Container for AdfsContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let mut children = Vec::new();

        // Read boot block at sector 6
        let boot = read_sector(&*reader, 6)?;

        // Validate checksum
        if !adfs_checksum(&boot) {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid ADFS checksum",
            ));
        }

        // Parse disc record
        let dr = DiscRecord::parse(&boot).ok_or_else(|| {
            io::Error::new(io::ErrorKind::InvalidData, "invalid disc record")
        })?;

        // Disc must have non-zero size
        if dr.disc_size == 0 && dr.disc_size_high == 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "zero disc size",
            ));
        }

        // Primary ADFS partition
        let nr_sects = dr.sectors();
        if nr_sects > 0 {
            let length = nr_sects * SECTOR_SIZE;
            children.push(Child {
                index: 0,
                offset: 0,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), 0, length)),
            });
        }

        // Check for secondary partition
        let part_type = boot[0x1fc] & 0x0f;
        if part_type != 0 {
            let heads = dr.effective_heads();
            let sectscyl = dr.secspertrack as u64 * heads;
            let cylinder = (boot[0x1fe] as u64) << 8 | boot[0x1fd] as u64;
            let start_sect = cylinder * sectscyl;

            if start_sect > 0 {
                let start = start_sect * SECTOR_SIZE;
                // Secondary partition extends to end of disk (we don't know actual size)
                // Container will detect its format and handle sizing

                match part_type {
                    PARTITION_RISCIX_MFM | PARTITION_RISCIX_SCSI => {
                        // RISCiX partition - parse its internal structure
                        parse_riscix(&reader, start_sect, &mut children)?;
                    }
                    PARTITION_LINUX => {
                        // Linux partition - parse its internal structure
                        parse_linux(&reader, start_sect, &mut children)?;
                    }
                    _ => {
                        // Unknown secondary partition - expose as raw slice
                        // Use a large size; actual detection will constrain it
                        children.push(Child {
                            index: 1,
                            offset: start,
                            reader: Arc::new(SliceReader::new(
                                Arc::clone(&reader),
                                start,
                                u64::MAX - start,
                            )),
                        });
                    }
                }
            }
        }

        Ok(children)
    }
}

/// Parse RISCiX partition table
fn parse_riscix(
    reader: &Arc<dyn Reader + Send + Sync>,
    start_sect: u64,
    children: &mut Vec<Child>,
) -> io::Result<()> {
    let sector = read_sector(&**reader, start_sect)?;

    // Check RISCiX magic
    let magic = read_le32(&sector, 0);
    if magic != RISCIX_MAGIC {
        // Not RISCiX, just add as single partition
        let start = start_sect * SECTOR_SIZE;
        children.push(Child {
            index: 1,
            offset: start,
            reader: Arc::new(SliceReader::new(Arc::clone(reader), start, u64::MAX - start)),
        });
        return Ok(());
    }

    // First 2 sectors are boot area
    let boot_size = 2.min(1) * SECTOR_SIZE; // At least 2 sectors for boot
    children.push(Child {
        index: 1,
        offset: start_sect * SECTOR_SIZE,
        reader: Arc::new(SliceReader::new(
            Arc::clone(reader),
            start_sect * SECTOR_SIZE,
            boot_size,
        )),
    });

    // Parse 8 partition entries starting at offset 8
    let mut slot = 2u32;
    for i in 0..8 {
        let entry_off = 8 + i * 28; // Each entry is 28 bytes
        let start = read_le32(&sector, entry_off);
        let length = read_le32(&sector, entry_off + 4);
        let one = read_le32(&sector, entry_off + 8);
        let name = &sector[entry_off + 12..entry_off + 28];

        // Skip invalid entries
        if one == 0 {
            continue;
        }
        // Skip "All" partition (represents whole disk)
        if name.starts_with(b"All\0") {
            continue;
        }

        if start > 0 && length > 0 {
            let start_bytes = start as u64 * SECTOR_SIZE;
            let length_bytes = length as u64 * SECTOR_SIZE;
            children.push(Child {
                index: slot,
                offset: start_bytes,
                reader: Arc::new(SliceReader::new(Arc::clone(reader), start_bytes, length_bytes)),
            });
            slot += 1;
        }
    }

    Ok(())
}

/// Parse Linux partition table (Acorn Linux format)
fn parse_linux(
    reader: &Arc<dyn Reader + Send + Sync>,
    start_sect: u64,
    children: &mut Vec<Child>,
) -> io::Result<()> {
    let sector = read_sector(&**reader, start_sect)?;

    // First 2 sectors are boot area
    let boot_size = 2 * SECTOR_SIZE;
    children.push(Child {
        index: 1,
        offset: start_sect * SECTOR_SIZE,
        reader: Arc::new(SliceReader::new(
            Arc::clone(reader),
            start_sect * SECTOR_SIZE,
            boot_size,
        )),
    });

    // Parse Linux partition entries (12 bytes each: magic, start, size)
    let mut slot = 2u32;
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
                index: slot,
                offset: abs_start,
                reader: Arc::new(SliceReader::new(Arc::clone(reader), abs_start, length)),
            });
            slot += 1;
        }

        offset += 12;
    }

    Ok(())
}
