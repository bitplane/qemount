//! EESOX SCSI partition table container
//!
//! EESOX SCSI controller partition format. Table at sector 7.
//! Data is XOR "encrypted" with "Neil Critchell  " (16 bytes).
//! Partition sizes are inferred from gaps between start addresses.

use super::{eesox_decrypt, read_le32, read_sector, SECTOR_SIZE};
use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// EESOX partition table container
pub struct EesoxContainer;

/// Static instance for registry
pub static EESOX: EesoxContainer = EesoxContainer;

/// EESOX partition entry size (32 bytes)
/// struct eesox_part { magic[6], name[10], start, unused6, unused7, unused8 }
const ENTRY_SIZE: usize = 32;

impl Container for EesoxContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Read sector 7
        let sector = read_sector(&*reader, 7)?;

        // Decrypt the first 256 bytes
        let decrypted = eesox_decrypt(&sector[..256]);

        // Parse partition entries and collect starts
        let mut partitions: Vec<u64> = Vec::new();

        for i in 0..8 {
            let entry_off = i * ENTRY_SIZE;
            if entry_off + ENTRY_SIZE > 256 {
                break;
            }

            // Check magic "Eesox"
            if &decrypted[entry_off..entry_off + 5] != b"Eesox" {
                break;
            }

            // Start sector at offset +16 (after magic[6] + name[10])
            let start = read_le32(&decrypted, entry_off + 16);
            partitions.push(start as u64);
        }

        if partitions.is_empty() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "no EESOX partitions found",
            ));
        }

        // Build children - size is determined by next partition's start
        let mut children = Vec::new();

        for (i, &start) in partitions.iter().enumerate() {
            let start_bytes = start * SECTOR_SIZE;

            // Size extends to next partition, or to end of disk for last partition
            let end_sect = if i + 1 < partitions.len() {
                partitions[i + 1]
            } else {
                // For last partition, we don't know disk size
                // Use a large value; detection will constrain it
                u64::MAX / SECTOR_SIZE
            };

            let size = end_sect.saturating_sub(start);
            if size > 0 {
                let length = size * SECTOR_SIZE;
                children.push(Child {
                    index: i as u32,
                    offset: start_bytes,
                    reader: Arc::new(SliceReader::new(Arc::clone(&reader), start_bytes, length)),
                });
            }
        }

        Ok(children)
    }
}
