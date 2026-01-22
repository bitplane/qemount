//! Bochs disk image reader
//!
//! Parses Bochs "Redolog Growing" disk image format.

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const BOCHS_MAGIC: &[u8; 22] = b"Bochs Virtual HD Image";
const REDOLOG_TYPE: &[u8; 7] = b"Redolog";
const GROWING_SUBTYPE: &[u8; 7] = b"Growing";
const CATALOG_UNALLOCATED: u32 = 0xffffffff;

/// Bochs disk image container
pub struct BochsContainer;

/// Static instance for registry
pub static BOCHS: BochsContainer = BochsContainer;

impl Container for BochsContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let bochs_reader = BochsReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(bochs_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through Bochs catalog
pub struct BochsReader {
    parent: Arc<dyn Reader + Send + Sync>,
    catalog: Vec<u32>,
    extent_size: u64,
    bitmap_size: u64,
    data_offset: u64,
    virtual_size: u64,
}

impl BochsReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header (need at least 96 bytes for v2 format)
        let mut header = [0u8; 96];
        if parent.read_at(0, &mut header)? < 96 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short Bochs header read",
            ));
        }

        // Check magic (first 22 bytes of 32-byte field)
        if &header[0..22] != BOCHS_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid Bochs magic",
            ));
        }

        // Check type and subtype (16-byte fields)
        if &header[32..39] != REDOLOG_TYPE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "not a Bochs Redolog image",
            ));
        }
        if &header[48..55] != GROWING_SUBTYPE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "not a Bochs Growing image",
            ));
        }

        // Parse header fields (little-endian)
        let version =
            u32::from_le_bytes([header[64], header[65], header[66], header[67]]);
        let header_size =
            u32::from_le_bytes([header[68], header[69], header[70], header[71]]) as u64;
        let catalog_size =
            u32::from_le_bytes([header[72], header[73], header[74], header[75]]) as usize;
        let bitmap_size =
            u32::from_le_bytes([header[76], header[77], header[78], header[79]]) as u64;
        let extent_size =
            u32::from_le_bytes([header[80], header[81], header[82], header[83]]) as u64;

        // Disk size offset depends on version
        // v1 (0x00010000): disk_size at offset 84
        // v2 (0x00020000): disk_size at offset 88 (4-byte reserved before it)
        let disk_size = if version == 0x00010000 {
            u64::from_le_bytes([
                header[84], header[85], header[86], header[87],
                header[88], header[89], header[90], header[91],
            ])
        } else {
            u64::from_le_bytes([
                header[88], header[89], header[90], header[91],
                header[92], header[93], header[94], header[95],
            ])
        };

        // Validate extent_size
        if extent_size < 512 || (extent_size & (extent_size - 1)) != 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid Bochs extent_size",
            ));
        }

        // Limit catalog size to prevent memory issues
        if catalog_size > 1024 * 1024 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Bochs catalog too large",
            ));
        }

        // Read catalog (after header)
        let catalog_bytes = catalog_size * 4;
        let mut catalog_data = vec![0u8; catalog_bytes];
        if parent.read_at(header_size, &mut catalog_data)? != catalog_bytes {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short Bochs catalog read",
            ));
        }

        // Parse catalog (little-endian u32)
        let catalog: Vec<u32> = catalog_data
            .chunks_exact(4)
            .map(|chunk| u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
            .collect();

        // Data starts after header and catalog
        let data_offset = header_size + catalog_bytes as u64;

        // Bitmap is sector-aligned on disk (rounded up to 512)
        let bitmap_size_aligned = (bitmap_size + 511) & !511;

        Ok(Self {
            parent,
            catalog,
            extent_size,
            bitmap_size: bitmap_size_aligned,
            data_offset,
            virtual_size: disk_size,
        })
    }
}

impl Reader for BochsReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate extent index and offset within extent
        let extent_idx = (offset / self.extent_size) as usize;
        let in_extent = offset % self.extent_size;

        // How much can we read from this extent?
        let remaining_in_extent = self.extent_size - in_extent;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_extent as usize)
            .min(remaining_in_disk as usize);

        // Check catalog bounds
        if extent_idx >= self.catalog.len() {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        let catalog_entry = self.catalog[extent_idx];

        // Check for unallocated
        if catalog_entry == CATALOG_UNALLOCATED {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Calculate physical offset
        // Each allocated extent has: bitmap + data
        // Slot size = bitmap_size + extent_size
        let slot_size = self.bitmap_size + self.extent_size;

        let physical_offset = self.data_offset
            + (catalog_entry as u64 * slot_size)
            + self.bitmap_size
            + in_extent;

        self.parent.read_at(physical_offset, &mut buf[..to_read])
    }
}

// SAFETY: BochsReader only holds Arc and Vec, safe to send/share
unsafe impl Send for BochsReader {}
unsafe impl Sync for BochsReader {}
