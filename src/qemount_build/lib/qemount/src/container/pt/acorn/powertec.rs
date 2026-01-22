//! PowerTec SCSI partition table container
//!
//! PowerTec SCSI controller partition format. Table at sector 0.
//! Checksum: sum(bytes[0..510]) + 0x2a == data[511]
//! Rejects disks with MBR signature (0x55AA at 510-511)

use super::{powertec_checksum, read_le32, read_sector, SECTOR_SIZE};
use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// PowerTec partition table container
pub struct PowertecContainer;

/// Static instance for registry
pub static POWERTEC: PowertecContainer = PowertecContainer;

/// PowerTec partition entry size (28 bytes)
const ENTRY_SIZE: usize = 28;

impl Container for PowertecContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let mut children = Vec::new();

        // Read sector 0
        let sector = read_sector(&*reader, 0)?;

        // Validate PowerTec checksum (also rejects MBR)
        if !powertec_checksum(&sector) {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid PowerTec checksum or MBR detected",
            ));
        }

        // Parse 12 partition entries
        // struct ptec_part { unused1, unused2, start, size, unused5, type[8] }
        // = 4 + 4 + 4 + 4 + 4 + 8 = 28 bytes
        let mut slot = 0u32;

        for i in 0..12 {
            let entry_off = i * ENTRY_SIZE;
            if entry_off + ENTRY_SIZE > 512 {
                break;
            }

            // start at offset +8, size at offset +12
            let start = read_le32(&sector, entry_off + 8);
            let size = read_le32(&sector, entry_off + 12);

            if size > 0 {
                let start_bytes = start as u64 * SECTOR_SIZE;
                let length = size as u64 * SECTOR_SIZE;
                children.push(Child {
                    index: slot,
                    offset: start_bytes,
                    reader: Arc::new(SliceReader::new(Arc::clone(&reader), start_bytes, length)),
                });
                slot += 1;
            }
        }

        Ok(children)
    }
}
