//! VDI (VirtualBox Disk Image) reader
//!
//! Parses VDI format and provides virtual disk access through block map.

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const VDI_SIGNATURE: u32 = 0xbeda107f;
const VDI_UNALLOCATED: u32 = 0xFFFFFFFF;
const VDI_DISCARDED: u32 = 0xFFFFFFFE;

/// VDI disk image container
pub struct VdiContainer;

/// Static instance for registry
pub static VDI: VdiContainer = VdiContainer;

impl Container for VdiContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let vdi_reader = VdiReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(vdi_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through VDI block map
pub struct VdiReader {
    parent: Arc<dyn Reader + Send + Sync>,
    block_map: Vec<u32>,
    block_size: u64,
    data_offset: u64,
    virtual_size: u64,
}

impl VdiReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header (need up to 0x184 for blocks_in_image)
        let mut header = [0u8; 0x188];
        if parent.read_at(0, &mut header)? < 0x184 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short header read",
            ));
        }

        // Check signature at offset 0x40 (little-endian)
        let signature =
            u32::from_le_bytes([header[0x40], header[0x41], header[0x42], header[0x43]]);
        if signature != VDI_SIGNATURE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid VDI signature",
            ));
        }

        // Parse header fields (little-endian)
        let offset_bmap =
            u32::from_le_bytes([header[0x154], header[0x155], header[0x156], header[0x157]])
                as u64;
        let offset_data =
            u32::from_le_bytes([header[0x158], header[0x159], header[0x15a], header[0x15b]])
                as u64;
        let disk_size = u64::from_le_bytes([
            header[0x170],
            header[0x171],
            header[0x172],
            header[0x173],
            header[0x174],
            header[0x175],
            header[0x176],
            header[0x177],
        ]);
        let block_size =
            u32::from_le_bytes([header[0x178], header[0x179], header[0x17a], header[0x17b]])
                as u64;
        let blocks_in_image =
            u32::from_le_bytes([header[0x180], header[0x181], header[0x182], header[0x183]])
                as usize;

        // Validate block_size
        if block_size == 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid block_size",
            ));
        }

        // Read block map
        let bmap_bytes = blocks_in_image * 4;
        let mut bmap_data = vec![0u8; bmap_bytes];
        if parent.read_at(offset_bmap, &mut bmap_data)? != bmap_bytes {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short block map read",
            ));
        }

        // Parse block map (little-endian u32)
        let block_map: Vec<u32> = bmap_data
            .chunks_exact(4)
            .map(|chunk| u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
            .collect();

        Ok(Self {
            parent,
            block_map,
            block_size,
            data_offset: offset_data,
            virtual_size: disk_size,
        })
    }
}

impl Reader for VdiReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate block index and offset within block
        let block_idx = (offset / self.block_size) as usize;
        let in_block = offset % self.block_size;

        // How much can we read from this block?
        let remaining_in_block = self.block_size - in_block;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_block as usize)
            .min(remaining_in_disk as usize);

        // Check bounds
        if block_idx >= self.block_map.len() {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        let bmap_entry = self.block_map[block_idx];

        // Check for unallocated or discarded blocks
        if bmap_entry == VDI_UNALLOCATED || bmap_entry == VDI_DISCARDED {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Calculate physical offset
        let physical_offset = self.data_offset + (bmap_entry as u64 * self.block_size) + in_block;
        self.parent.read_at(physical_offset, &mut buf[..to_read])
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: VdiReader only holds Arc and Vec, safe to send/share
unsafe impl Send for VdiReader {}
unsafe impl Sync for VdiReader {}
