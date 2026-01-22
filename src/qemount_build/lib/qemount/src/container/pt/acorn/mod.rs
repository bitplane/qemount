//! Acorn partition table formats
//!
//! Supports multiple Acorn/RISC OS partition schemes:
//! - ADFS: Native Acorn format
//! - ICS: Integrated Computer Solutions SCSI
//! - PowerTec: PowerTec SCSI
//! - EESOX: EESOX SCSI
//! - Cumana: Cumana SCSI (chained)
//!
//! Sub-partition formats (detected within ADFS/Cumana):
//! - RISCiX: Unix for Acorn
//! - Linux: Linux native/swap

pub mod adfs;
pub mod cumana;
pub mod eesox;
pub mod ics;
pub mod powertec;

use crate::detect::Reader;
use std::io;

/// Sector size (always 512 for Acorn)
pub const SECTOR_SIZE: u64 = 512;

/// ADFS boot block checksum (from Linux kernel)
/// Iterates bytes 510→0 with carry folding, compares to byte 511
pub fn adfs_checksum(data: &[u8]) -> bool {
    if data.len() < 512 {
        return false;
    }
    let mut result: u32 = 0;
    for i in (0..511).rev() {
        result = (result & 0xff) + (result >> 8) + data[i] as u32;
    }
    (result & 0xff) as u8 == data[511]
}

/// ICS checksum: sum(bytes[0..507]) + 0x50617274 == *(le32*)&data[508]
pub fn ics_checksum(data: &[u8]) -> bool {
    if data.len() < 512 {
        return false;
    }
    let mut sum: u32 = 0x50617274; // "Part" in ASCII
    for &b in &data[..508] {
        sum = sum.wrapping_add(b as u32);
    }
    let stored = u32::from_le_bytes([data[508], data[509], data[510], data[511]]);
    sum == stored
}

/// PowerTec checksum: sum(bytes[0..510]) + 0x2a == data[511]
/// Also rejects MBR signature (0x55AA at 510-511)
pub fn powertec_checksum(data: &[u8]) -> bool {
    if data.len() < 512 {
        return false;
    }
    // Reject if looks like MBR
    if data[510] == 0x55 && data[511] == 0xaa {
        return false;
    }
    let mut checksum: u8 = 0x2a;
    for &b in &data[..511] {
        checksum = checksum.wrapping_add(b);
    }
    checksum == data[511]
}

/// EESOX XOR decryption key
const EESOX_KEY: &[u8; 16] = b"Neil Critchell  ";

/// Decrypt EESOX partition table (XOR with key)
pub fn eesox_decrypt(data: &[u8]) -> Vec<u8> {
    data.iter()
        .enumerate()
        .map(|(i, &b)| b ^ EESOX_KEY[i & 15])
        .collect()
}

/// ADFS disc record at offset 0x1c0 within boot block
pub struct DiscRecord {
    pub log2secsize: u8,
    pub secspertrack: u8,
    pub heads: u8,
    pub lowsector: u8,
    pub disc_size: u32,
    pub disc_size_high: u32,
}

impl DiscRecord {
    /// Parse disc record from boot block data (offset 0x1c0)
    pub fn parse(data: &[u8]) -> Option<Self> {
        if data.len() < 0x1c0 + 48 {
            return None;
        }
        let dr = &data[0x1c0..];
        Some(Self {
            log2secsize: dr[0],
            secspertrack: dr[1],
            heads: dr[2],
            lowsector: dr[8],
            disc_size: u32::from_le_bytes([dr[16], dr[17], dr[18], dr[19]]),
            disc_size_high: u32::from_le_bytes([dr[36], dr[37], dr[38], dr[39]]),
        })
    }

    /// Calculate partition size in sectors
    pub fn sectors(&self) -> u64 {
        ((self.disc_size_high as u64) << 23) | ((self.disc_size as u64) >> 9)
    }

    /// Get effective heads count (includes lowsector bit 6)
    pub fn effective_heads(&self) -> u64 {
        self.heads as u64 + if (self.lowsector & 0x40) != 0 { 1 } else { 0 }
    }
}

/// Partition type identifiers (byte 0x1fc lower nibble)
pub const PARTITION_RISCIX_MFM: u8 = 1;
pub const PARTITION_RISCIX_SCSI: u8 = 2;
pub const PARTITION_LINUX: u8 = 9;

/// RISCiX magic number
pub const RISCIX_MAGIC: u32 = 0x4a657320;

/// Linux partition magic numbers
pub const LINUX_NATIVE_MAGIC: u32 = 0xdeafa1de;
pub const LINUX_SWAP_MAGIC: u32 = 0xdeafab1e;

// Helper functions
pub fn read_sector(reader: &dyn Reader, sector: u64) -> io::Result<[u8; 512]> {
    let mut buf = [0u8; 512];
    let n = reader.read_at(sector * SECTOR_SIZE, &mut buf)?;
    if n != 512 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(buf)
}

pub fn read_le32(data: &[u8], offset: usize) -> u32 {
    u32::from_le_bytes([
        data[offset],
        data[offset + 1],
        data[offset + 2],
        data[offset + 3],
    ])
}
