//! VHDX (Hyper-V Virtual Hard Disk v2) reader
//!
//! Parses VHDX format and provides virtual disk access through BAT.

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const VHDX_FILE_SIGNATURE: &[u8; 8] = b"vhdxfile";
const VHDX_REGION_SIGNATURE: u32 = 0x69676572; // "regi"

// Region GUIDs (little-endian)
const BAT_GUID: [u8; 16] = [
    0x66, 0x77, 0xC2, 0x2D, 0x23, 0xF6, 0x00, 0x42,
    0x9D, 0x64, 0x11, 0x5E, 0x9B, 0xFD, 0x4A, 0x08,
];
const METADATA_GUID: [u8; 16] = [
    0x06, 0xA2, 0x7C, 0x8B, 0x90, 0x47, 0x9A, 0x4B,
    0xB8, 0xFE, 0x57, 0x5F, 0x05, 0x0F, 0x88, 0x6E,
];

// Metadata item GUIDs
const VIRTUAL_DISK_SIZE_GUID: [u8; 16] = [
    0x24, 0x42, 0xA5, 0x2F, 0x1B, 0xCD, 0x76, 0x48,
    0xB2, 0x11, 0x5D, 0xBE, 0xD8, 0x3B, 0xF4, 0xB8,
];
const FILE_PARAMETERS_GUID: [u8; 16] = [
    0x37, 0x67, 0xa1, 0xca, 0x36, 0xfa, 0x43, 0x4d,
    0xb3, 0xb6, 0x33, 0xf0, 0xaa, 0x44, 0xe7, 0x6b,
];

// BAT entry masks
const BAT_STATE_MASK: u64 = 0x07;
const BAT_FILE_OFF_MASK: u64 = 0xFFFFFFFFFFF00000;
const BAT_STATE_FULLY_PRESENT: u64 = 6;

/// VHDX disk image container
pub struct VhdxContainer;

/// Static instance for registry
pub static VHDX: VhdxContainer = VhdxContainer;

impl Container for VhdxContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let vhdx_reader = VhdxReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(vhdx_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through VHDX BAT
pub struct VhdxReader {
    parent: Arc<dyn Reader + Send + Sync>,
    bat: Vec<u64>,
    block_size: u64,
    virtual_size: u64,
}

impl VhdxReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Check file signature
        let mut sig = [0u8; 8];
        if parent.read_at(0, &mut sig)? != 8 || &sig != VHDX_FILE_SIGNATURE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid VHDX signature",
            ));
        }

        // Read region table at 192KB (0x30000)
        let mut region_header = [0u8; 16];
        if parent.read_at(0x30000, &mut region_header)? != 16 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short region header read",
            ));
        }

        let region_sig = u32::from_le_bytes([
            region_header[0],
            region_header[1],
            region_header[2],
            region_header[3],
        ]);
        if region_sig != VHDX_REGION_SIGNATURE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid region table signature",
            ));
        }

        let entry_count = u32::from_le_bytes([
            region_header[8],
            region_header[9],
            region_header[10],
            region_header[11],
        ]) as usize;

        // Read region entries (32 bytes each, starting at offset 16)
        let mut bat_offset = 0u64;
        let mut bat_length = 0u64;
        let mut metadata_offset = 0u64;

        for i in 0..entry_count.min(2047) {
            let entry_offset = 0x30000 + 16 + (i * 32);
            let mut entry = [0u8; 32];
            if parent.read_at(entry_offset as u64, &mut entry)? != 32 {
                break;
            }

            let guid = &entry[0..16];
            let file_offset = u64::from_le_bytes([
                entry[16], entry[17], entry[18], entry[19],
                entry[20], entry[21], entry[22], entry[23],
            ]);
            let length = u32::from_le_bytes([entry[24], entry[25], entry[26], entry[27]]) as u64;

            if guid == &BAT_GUID {
                bat_offset = file_offset;
                bat_length = length;
            } else if guid == &METADATA_GUID {
                metadata_offset = file_offset;
            }
        }

        if bat_offset == 0 || metadata_offset == 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "missing BAT or metadata region",
            ));
        }

        // Parse metadata to get virtual size and block size
        let (virtual_size, block_size) = Self::parse_metadata(&*parent, metadata_offset)?;

        // Read BAT
        let bat_entries = (bat_length / 8) as usize;
        let mut bat_data = vec![0u8; bat_entries * 8];
        let read_len = parent.read_at(bat_offset, &mut bat_data)?;
        let actual_entries = read_len / 8;

        let bat: Vec<u64> = bat_data[..actual_entries * 8]
            .chunks_exact(8)
            .map(|chunk| {
                u64::from_le_bytes([
                    chunk[0], chunk[1], chunk[2], chunk[3],
                    chunk[4], chunk[5], chunk[6], chunk[7],
                ])
            })
            .collect();

        Ok(Self {
            parent,
            bat,
            block_size,
            virtual_size,
        })
    }

    fn parse_metadata(parent: &dyn Reader, metadata_offset: u64) -> io::Result<(u64, u64)> {
        // Metadata header: signature (8) + reserved (2) + entry_count (2)
        let mut header = [0u8; 32];
        if parent.read_at(metadata_offset, &mut header)? != 32 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short metadata header",
            ));
        }

        let entry_count =
            u16::from_le_bytes([header[10], header[11]]) as usize;

        let mut virtual_size = 0u64;
        let mut block_size = 0u32;

        // Metadata entries start at offset 32, each is 32 bytes
        for i in 0..entry_count.min(2047) {
            let entry_off = metadata_offset + 32 + (i * 32) as u64;
            let mut entry = [0u8; 32];
            if parent.read_at(entry_off, &mut entry)? != 32 {
                break;
            }

            let guid = &entry[0..16];
            let item_offset =
                u32::from_le_bytes([entry[16], entry[17], entry[18], entry[19]]) as u64;
            let item_length =
                u32::from_le_bytes([entry[20], entry[21], entry[22], entry[23]]) as usize;

            if guid == &VIRTUAL_DISK_SIZE_GUID && item_length >= 8 {
                let mut buf = [0u8; 8];
                parent.read_at(metadata_offset + item_offset, &mut buf)?;
                virtual_size = u64::from_le_bytes(buf);
            } else if guid == &FILE_PARAMETERS_GUID && item_length >= 8 {
                let mut buf = [0u8; 8];
                parent.read_at(metadata_offset + item_offset, &mut buf)?;
                block_size = u32::from_le_bytes([buf[0], buf[1], buf[2], buf[3]]);
            }
        }

        if virtual_size == 0 || block_size == 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "missing virtual size or block size in metadata",
            ));
        }

        Ok((virtual_size, block_size as u64))
    }
}

impl Reader for VhdxReader {
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
        if block_idx >= self.bat.len() {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        let bat_entry = self.bat[block_idx];
        let state = bat_entry & BAT_STATE_MASK;

        // Only FULLY_PRESENT (6) has data
        if state != BAT_STATE_FULLY_PRESENT {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // File offset from upper bits (already in bytes, 1MB aligned)
        let file_offset = bat_entry & BAT_FILE_OFF_MASK;
        let physical_offset = file_offset + in_block;
        self.parent.read_at(physical_offset, &mut buf[..to_read])
    }
}

// SAFETY: VhdxReader only holds Arc and Vec, safe to send/share
unsafe impl Send for VhdxReader {}
unsafe impl Sync for VhdxReader {}
