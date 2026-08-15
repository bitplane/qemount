//! ICS (Integrated Computer Solutions) partition table container
//!
//! ICS SCSI controller partition format. Table at sector 0.
//! Checksum: sum(bytes[0..507]) + 0x50617274 == *(le32*)&data[508]

use super::{ics_checksum, read_le32, read_sector, SECTOR_SIZE};
use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// ICS partition table container
pub struct IcsContainer;

/// Static instance for registry
pub static ICS: IcsContainer = IcsContainer;

impl Container for IcsContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let mut children = Vec::new();

        // Read sector 0
        let sector = read_sector(&*reader, 0)?;

        // Validate ICS checksum
        if !ics_checksum(&sector) {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid ICS checksum",
            ));
        }

        // Parse partition entries (8 bytes each: start, size)
        let mut slot = 0u32;
        let mut offset = 0usize;

        while offset + 8 <= 508 {
            let start = read_le32(&sector, offset);
            let size = read_le32(&sector, offset + 4) as i32; // signed!

            if size == 0 {
                break;
            }

            let mut actual_start = start;
            let mut actual_size = if size < 0 { (-size) as u32 } else { size as u32 };

            // Negative size indicates non-ADFS partition
            // Check if first sector contains "LinuxPart" marker
            if size < 0 && actual_size > 1 {
                if let Ok(part_sector) = read_sector(&*reader, start as u64) {
                    if part_sector.starts_with(b"LinuxPart") {
                        // Skip the marker sector
                        actual_start += 1;
                        actual_size -= 1;
                    }
                }
            }

            if actual_size > 0 {
                let start_bytes = actual_start as u64 * SECTOR_SIZE;
                let length = actual_size as u64 * SECTOR_SIZE;
                children.push(Child {
                    index: slot,
                    offset: start_bytes,
                    reader: Arc::new(SliceReader::new(Arc::clone(&reader), start_bytes, length)),
                });
                slot += 1;
            }

            offset += 8;
        }

        Ok(children)
    }
}
