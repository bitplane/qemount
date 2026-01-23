//! Parallels disk image reader
//!
//! Parses Parallels HDD format and provides virtual disk access through BAT.

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const HEADER_SIZE: u64 = 64;
const SECTOR_SIZE: u64 = 512;
const MAGIC_OLD: &[u8; 16] = b"WithoutFreeSpace";
const MAGIC_EXT: &[u8; 16] = b"WithouFreSpacExt";

/// Parallels disk image container
pub struct ParallelsContainer;

/// Static instance for registry
pub static PARALLELS: ParallelsContainer = ParallelsContainer;

impl Container for ParallelsContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let parallels_reader = ParallelsReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(parallels_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through Parallels BAT
pub struct ParallelsReader {
    parent: Arc<dyn Reader + Send + Sync>,
    bat: Vec<u32>,
    cluster_size: u64,
    virtual_size: u64,
    extended: bool,
}

impl ParallelsReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header
        let mut header = [0u8; 64];
        if parent.read_at(0, &mut header)? != 64 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short header read",
            ));
        }

        // Check magic
        let magic = &header[0..16];
        let extended = if magic == MAGIC_EXT {
            true
        } else if magic == MAGIC_OLD {
            false
        } else {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid Parallels magic",
            ));
        };

        // Parse header fields (little-endian)
        let version = u32::from_le_bytes([header[16], header[17], header[18], header[19]]);
        if version != 2 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "unsupported Parallels version",
            ));
        }

        let tracks = u32::from_le_bytes([header[28], header[29], header[30], header[31]]);
        let bat_entries = u32::from_le_bytes([header[32], header[33], header[34], header[35]]);
        let nb_sectors = u64::from_le_bytes([
            header[36], header[37], header[38], header[39],
            header[40], header[41], header[42], header[43],
        ]);

        let cluster_size = tracks as u64 * SECTOR_SIZE;
        let virtual_size = nb_sectors * SECTOR_SIZE;

        // Read BAT
        let bat_size = bat_entries as usize * 4;
        let mut bat_bytes = vec![0u8; bat_size];
        if parent.read_at(HEADER_SIZE, &mut bat_bytes)? != bat_size {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short BAT read",
            ));
        }

        // Parse BAT entries
        let bat: Vec<u32> = bat_bytes
            .chunks_exact(4)
            .map(|chunk| u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
            .collect();

        Ok(Self {
            parent,
            bat,
            cluster_size,
            virtual_size,
            extended,
        })
    }
}

impl Reader for ParallelsReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate cluster and offset within cluster
        let cluster_idx = (offset / self.cluster_size) as usize;
        let intra_cluster = offset % self.cluster_size;

        // Check bounds
        if cluster_idx >= self.bat.len() {
            return Ok(0);
        }

        // How much can we read from this cluster?
        let remaining_in_cluster = self.cluster_size - intra_cluster;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_cluster as usize)
            .min(remaining_in_disk as usize);

        let bat_entry = self.bat[cluster_idx];

        if bat_entry == 0 {
            // Sparse cluster - return zeros
            buf[..to_read].fill(0);
            Ok(to_read)
        } else {
            // Calculate physical offset
            // Extended format: entry × tracks × 512
            // Old format: entry × 512
            let physical_offset = if self.extended {
                bat_entry as u64 * self.cluster_size + intra_cluster
            } else {
                bat_entry as u64 * SECTOR_SIZE + intra_cluster
            };

            self.parent.read_at(physical_offset, &mut buf[..to_read])
        }
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: ParallelsReader only holds Arc and Vec, safe to send/share
unsafe impl Send for ParallelsReader {}
unsafe impl Sync for ParallelsReader {}
