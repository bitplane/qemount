//! VHD (Virtual Hard Disk) reader
//!
//! Parses Microsoft VHD format and provides virtual disk access.
//! Supports Fixed (type 2), Dynamic (type 3), and Differencing (type 4).

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const VHD_MAGIC: &[u8; 8] = b"conectix";
const VHD_DYNAMIC_MAGIC: &[u8; 8] = b"cxsparse";
const VHD_FIXED: u32 = 2;
const VHD_DYNAMIC: u32 = 3;
const VHD_DIFFERENCING: u32 = 4;
const VHD_UNALLOCATED: u32 = 0xFFFFFFFF;

/// VHD disk image container
pub struct VhdContainer;

/// Static instance for registry
pub static VHD: VhdContainer = VhdContainer;

impl Container for VhdContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let vhd_reader = VhdReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(vhd_reader),
        }])
    }
}

/// VHD variant
enum VhdVariant {
    /// Fixed VHD - raw data at offset 0
    Fixed,
    /// Dynamic/Differencing VHD - uses BAT
    Dynamic {
        bat: Vec<u32>,
        block_size: u64,
        bitmap_size: u64,
    },
}

/// Reader that translates virtual disk offsets through VHD BAT
pub struct VhdReader {
    parent: Arc<dyn Reader + Send + Sync>,
    variant: VhdVariant,
    virtual_size: u64,
}

impl VhdReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read footer (512 bytes at offset 0 for dynamic, or check end for fixed)
        let mut footer = [0u8; 512];
        if parent.read_at(0, &mut footer)? != 512 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short footer read",
            ));
        }

        // Check magic at offset 0 (dynamic/differencing have copy here)
        if &footer[0..8] != VHD_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid VHD magic",
            ));
        }

        // Parse footer (big-endian)
        let data_offset = u64::from_be_bytes([
            footer[0x10], footer[0x11], footer[0x12], footer[0x13],
            footer[0x14], footer[0x15], footer[0x16], footer[0x17],
        ]);
        let virtual_size = u64::from_be_bytes([
            footer[0x30], footer[0x31], footer[0x32], footer[0x33],
            footer[0x34], footer[0x35], footer[0x36], footer[0x37],
        ]);
        let disk_type =
            u32::from_be_bytes([footer[0x3c], footer[0x3d], footer[0x3e], footer[0x3f]]);

        let variant = match disk_type {
            VHD_FIXED => {
                // Fixed VHD: raw data starts at offset 0, footer at end
                // Data is at offset 0, size is virtual_size
                VhdVariant::Fixed
            }
            VHD_DYNAMIC | VHD_DIFFERENCING => {
                // Read dynamic header (1024 bytes)
                let mut dyn_header = [0u8; 1024];
                if parent.read_at(data_offset, &mut dyn_header)? != 1024 {
                    return Err(io::Error::new(
                        io::ErrorKind::UnexpectedEof,
                        "short dynamic header read",
                    ));
                }

                // Check dynamic magic
                if &dyn_header[0..8] != VHD_DYNAMIC_MAGIC {
                    return Err(io::Error::new(
                        io::ErrorKind::InvalidData,
                        "invalid VHD dynamic header magic",
                    ));
                }

                // Parse dynamic header (big-endian)
                let table_offset = u64::from_be_bytes([
                    dyn_header[0x10], dyn_header[0x11], dyn_header[0x12], dyn_header[0x13],
                    dyn_header[0x14], dyn_header[0x15], dyn_header[0x16], dyn_header[0x17],
                ]);
                let max_table_entries = u32::from_be_bytes([
                    dyn_header[0x1c], dyn_header[0x1d], dyn_header[0x1e], dyn_header[0x1f],
                ]) as usize;
                let block_size = u32::from_be_bytes([
                    dyn_header[0x20], dyn_header[0x21], dyn_header[0x22], dyn_header[0x23],
                ]) as u64;

                if block_size == 0 {
                    return Err(io::Error::new(
                        io::ErrorKind::InvalidData,
                        "invalid block_size",
                    ));
                }

                // Bitmap size = ceil(block_size / 512 / 8) rounded up to 512
                let bitmap_size = (((block_size / 512) + 7) / 8 + 511) & !511;

                // Read BAT
                let bat_bytes = max_table_entries * 4;
                let mut bat_data = vec![0u8; bat_bytes];
                if parent.read_at(table_offset, &mut bat_data)? != bat_bytes {
                    return Err(io::Error::new(
                        io::ErrorKind::UnexpectedEof,
                        "short BAT read",
                    ));
                }

                let bat: Vec<u32> = bat_data
                    .chunks_exact(4)
                    .map(|chunk| u32::from_be_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
                    .collect();

                VhdVariant::Dynamic { bat, block_size, bitmap_size }
            }
            _ => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "unknown VHD type",
                ));
            }
        };

        Ok(Self {
            parent,
            variant,
            virtual_size,
        })
    }
}

impl Reader for VhdReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf.len().min(remaining_in_disk as usize);

        match &self.variant {
            VhdVariant::Fixed => {
                // Fixed VHD: direct passthrough, data at offset 0
                self.parent.read_at(offset, &mut buf[..to_read])
            }
            VhdVariant::Dynamic { bat, block_size, bitmap_size } => {
                let block_idx = (offset / block_size) as usize;
                let in_block = offset % block_size;

                let remaining_in_block = block_size - in_block;
                let to_read = to_read.min(remaining_in_block as usize);

                if block_idx >= bat.len() {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let bat_entry = bat[block_idx];

                if bat_entry == VHD_UNALLOCATED {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                // BAT entry is sector number, skip bitmap at start of block
                let physical_offset = (bat_entry as u64 * 512) + bitmap_size + in_block;
                self.parent.read_at(physical_offset, &mut buf[..to_read])
            }
        }
    }
}

// SAFETY: VhdReader only holds Arc and Vec, safe to send/share
unsafe impl Send for VhdReader {}
unsafe impl Sync for VhdReader {}
