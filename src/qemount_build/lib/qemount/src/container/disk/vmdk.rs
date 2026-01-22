//! VMDK (VMware Virtual Machine Disk) reader
//!
//! Supports multiple VMDK variants:
//! - VMDK3 (COWD) - legacy VMFS sparse
//! - VMDK4 (KDMV) - modern sparse
//! - VMDK4 stream-optimized - compressed with deflate
//! - seSparse - ESXi sparse format

use crate::container::{Child, Container};
use crate::detect::Reader;
use flate2::read::DeflateDecoder;
use std::io::{self, Read};
use std::sync::Arc;

const VMDK3_MAGIC: u32 = 0x444F5743; // "COWD"
const VMDK4_MAGIC: u32 = 0x564D444B; // "KDMV"
const SESPARSE_MAGIC: u64 = 0x00000000cafebabe;

const VMDK4_FLAG_COMPRESS: u32 = 0x10000;
const VMDK4_FLAG_ZERO_GRAIN: u32 = 0x4;
const VMDK4_GTE_ZEROED: u32 = 1;

/// VMDK disk image container
pub struct VmdkContainer;

/// Static instance for registry
pub static VMDK: VmdkContainer = VmdkContainer;

impl Container for VmdkContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let vmdk_reader = VmdkReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(vmdk_reader),
        }])
    }
}

/// VMDK variant-specific data
enum VmdkVariant {
    /// VMDK3 (COWD) - single-level lookup
    Vmdk3 {
        l1_table: Vec<u32>,
        l1_offset: u64,
    },
    /// VMDK4 (KDMV) - two-level GD/GT
    Vmdk4 {
        gd: Vec<u32>,
        num_gtes_per_gt: u32,
        has_zero_grain: bool,
    },
    /// VMDK4 stream-optimized (compressed)
    Vmdk4Compressed {
        gd: Vec<u32>,
        num_gtes_per_gt: u32,
    },
    /// seSparse (ESXi)
    SeSparse {
        gd: Vec<u64>,
        gt_size: u64,
    },
}

/// Reader that translates virtual disk offsets through VMDK structures
pub struct VmdkReader {
    parent: Arc<dyn Reader + Send + Sync>,
    variant: VmdkVariant,
    grain_size: u64,
    virtual_size: u64,
}

impl VmdkReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read first 8 bytes to determine variant
        let mut magic_buf = [0u8; 8];
        if parent.read_at(0, &mut magic_buf)? < 4 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short magic read",
            ));
        }

        let magic32 = u32::from_le_bytes([magic_buf[0], magic_buf[1], magic_buf[2], magic_buf[3]]);
        let magic64 = u64::from_le_bytes(magic_buf);

        match magic32 {
            VMDK3_MAGIC => Self::parse_vmdk3(parent),
            VMDK4_MAGIC => Self::parse_vmdk4(parent),
            _ if magic64 == SESPARSE_MAGIC => Self::parse_sesparse(parent),
            _ => Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid VMDK magic",
            )),
        }
    }

    fn parse_vmdk3(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // VMDK3 header is 44 bytes after magic
        let mut header = [0u8; 44];
        if parent.read_at(4, &mut header)? != 44 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short VMDK3 header",
            ));
        }

        let disk_sectors =
            u32::from_le_bytes([header[8], header[9], header[10], header[11]]) as u64;
        let granularity =
            u32::from_le_bytes([header[12], header[13], header[14], header[15]]) as u64;
        let l1dir_offset =
            u32::from_le_bytes([header[16], header[17], header[18], header[19]]) as u64;
        let l1dir_size =
            u32::from_le_bytes([header[20], header[21], header[22], header[23]]) as usize;

        let grain_size = granularity * 512;
        let virtual_size = disk_sectors * 512;

        // Read L1 table
        let l1_bytes = l1dir_size * 4;
        let mut l1_data = vec![0u8; l1_bytes];
        if parent.read_at(l1dir_offset * 512, &mut l1_data)? != l1_bytes {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short VMDK3 L1 read",
            ));
        }

        let l1_table: Vec<u32> = l1_data
            .chunks_exact(4)
            .map(|c| u32::from_le_bytes([c[0], c[1], c[2], c[3]]))
            .collect();

        Ok(Self {
            parent,
            variant: VmdkVariant::Vmdk3 {
                l1_table,
                l1_offset: l1dir_offset * 512,
            },
            grain_size,
            virtual_size,
        })
    }

    fn parse_vmdk4(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // VMDK4 header
        let mut header = [0u8; 80];
        if parent.read_at(0, &mut header)? != 80 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short VMDK4 header",
            ));
        }

        let flags = u32::from_le_bytes([header[8], header[9], header[10], header[11]]);
        let capacity = u64::from_le_bytes([
            header[12], header[13], header[14], header[15], header[16], header[17], header[18],
            header[19],
        ]);
        let granularity = u64::from_le_bytes([
            header[20], header[21], header[22], header[23], header[24], header[25], header[26],
            header[27],
        ]);
        let num_gtes_per_gt = u32::from_le_bytes([header[44], header[45], header[46], header[47]]);
        let gd_offset = u64::from_le_bytes([
            header[56], header[57], header[58], header[59], header[60], header[61], header[62],
            header[63],
        ]);

        let grain_size = granularity * 512;
        let virtual_size = capacity * 512;
        let is_compressed = flags & VMDK4_FLAG_COMPRESS != 0;
        let has_zero_grain = flags & VMDK4_FLAG_ZERO_GRAIN != 0;

        // Calculate GD size
        let gt_coverage = num_gtes_per_gt as u64 * grain_size;
        let gd_entries = (virtual_size + gt_coverage - 1) / gt_coverage;

        // Read GD
        let gd_bytes = gd_entries as usize * 4;
        let mut gd_data = vec![0u8; gd_bytes];
        let read_len = parent.read_at(gd_offset * 512, &mut gd_data)?;
        let actual_entries = read_len / 4;

        let gd: Vec<u32> = gd_data[..actual_entries * 4]
            .chunks_exact(4)
            .map(|c| u32::from_le_bytes([c[0], c[1], c[2], c[3]]))
            .collect();

        let variant = if is_compressed {
            VmdkVariant::Vmdk4Compressed { gd, num_gtes_per_gt }
        } else {
            VmdkVariant::Vmdk4 {
                gd,
                num_gtes_per_gt,
                has_zero_grain,
            }
        };

        Ok(Self {
            parent,
            variant,
            grain_size,
            virtual_size,
        })
    }

    fn parse_sesparse(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // seSparse const header
        let mut header = [0u8; 64];
        if parent.read_at(0, &mut header)? != 64 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short seSparse header",
            ));
        }

        let capacity = u64::from_le_bytes([
            header[16], header[17], header[18], header[19], header[20], header[21], header[22],
            header[23],
        ]);
        let grain_size_bytes = u64::from_le_bytes([
            header[24], header[25], header[26], header[27], header[28], header[29], header[30],
            header[31],
        ]);
        let gt_size = u64::from_le_bytes([
            header[32], header[33], header[34], header[35], header[36], header[37], header[38],
            header[39],
        ]);
        let gd_offset = u64::from_le_bytes([
            header[40], header[41], header[42], header[43], header[44], header[45], header[46],
            header[47],
        ]);

        // Calculate GD size
        let gt_coverage = gt_size * grain_size_bytes;
        let gd_entries = if gt_coverage > 0 {
            (capacity + gt_coverage - 1) / gt_coverage
        } else {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid seSparse gt_size",
            ));
        };

        // Read GD (64-bit entries)
        let gd_bytes = gd_entries as usize * 8;
        let mut gd_data = vec![0u8; gd_bytes];
        let read_len = parent.read_at(gd_offset, &mut gd_data)?;
        let actual_entries = read_len / 8;

        let gd: Vec<u64> = gd_data[..actual_entries * 8]
            .chunks_exact(8)
            .map(|c| {
                u64::from_le_bytes([c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7]])
            })
            .collect();

        Ok(Self {
            parent,
            variant: VmdkVariant::SeSparse { gd, gt_size },
            grain_size: grain_size_bytes,
            virtual_size: capacity,
        })
    }

    fn read_gt_entry(&self, gt_offset: u64, gt_index: u64) -> io::Result<u32> {
        let mut buf = [0u8; 4];
        let offset = gt_offset + gt_index * 4;
        if self.parent.read_at(offset, &mut buf)? != 4 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short GT read",
            ));
        }
        Ok(u32::from_le_bytes(buf))
    }

    fn read_gt_entry_64(&self, gt_offset: u64, gt_index: u64) -> io::Result<u64> {
        let mut buf = [0u8; 8];
        let offset = gt_offset + gt_index * 8;
        if self.parent.read_at(offset, &mut buf)? != 8 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short GT read",
            ));
        }
        Ok(u64::from_le_bytes(buf))
    }

    fn read_compressed_grain(&self, grain_offset: u64) -> io::Result<Vec<u8>> {
        // Compressed grain marker: offset(8), size(4), type(4)
        let mut marker = [0u8; 16];
        if self.parent.read_at(grain_offset * 512, &mut marker)? != 16 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short grain marker",
            ));
        }

        let compressed_size =
            u32::from_le_bytes([marker[8], marker[9], marker[10], marker[11]]) as usize;

        // Read compressed data after marker
        let mut compressed = vec![0u8; compressed_size];
        self.parent
            .read_at(grain_offset * 512 + 16, &mut compressed)?;

        // Decompress
        let mut decoder = DeflateDecoder::new(&compressed[..]);
        let mut decompressed = vec![0u8; self.grain_size as usize];
        decoder.read_exact(&mut decompressed)?;

        Ok(decompressed)
    }
}

impl Reader for VmdkReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        let grain_idx = offset / self.grain_size;
        let in_grain = offset % self.grain_size;

        let remaining_in_grain = self.grain_size - in_grain;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_grain as usize)
            .min(remaining_in_disk as usize);

        match &self.variant {
            VmdkVariant::Vmdk3 { l1_table, .. } => {
                // Single-level lookup
                if grain_idx as usize >= l1_table.len() {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let grain_sector = l1_table[grain_idx as usize];
                if grain_sector == 0 {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let physical = grain_sector as u64 * 512 + in_grain;
                self.parent.read_at(physical, &mut buf[..to_read])
            }

            VmdkVariant::Vmdk4 {
                gd,
                num_gtes_per_gt,
                has_zero_grain,
            } => {
                // Two-level lookup
                let gd_idx = grain_idx / *num_gtes_per_gt as u64;
                let gt_idx = grain_idx % *num_gtes_per_gt as u64;

                if gd_idx as usize >= gd.len() {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let gt_sector = gd[gd_idx as usize];
                if gt_sector == 0 {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let grain_sector = self.read_gt_entry(gt_sector as u64 * 512, gt_idx)?;
                if grain_sector == 0 || (*has_zero_grain && grain_sector == VMDK4_GTE_ZEROED) {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let physical = grain_sector as u64 * 512 + in_grain;
                self.parent.read_at(physical, &mut buf[..to_read])
            }

            VmdkVariant::Vmdk4Compressed { gd, num_gtes_per_gt } => {
                let gd_idx = grain_idx / *num_gtes_per_gt as u64;
                let gt_idx = grain_idx % *num_gtes_per_gt as u64;

                if gd_idx as usize >= gd.len() {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let gt_sector = gd[gd_idx as usize];
                if gt_sector == 0 {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let grain_sector = self.read_gt_entry(gt_sector as u64 * 512, gt_idx)?;
                if grain_sector == 0 {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let decompressed = self.read_compressed_grain(grain_sector as u64)?;
                buf[..to_read].copy_from_slice(&decompressed[in_grain as usize..][..to_read]);
                Ok(to_read)
            }

            VmdkVariant::SeSparse { gd, gt_size } => {
                // seSparse two-level with 64-bit entries
                let gd_idx = grain_idx / *gt_size;
                let gt_idx = grain_idx % *gt_size;

                if gd_idx as usize >= gd.len() {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let gt_offset = gd[gd_idx as usize];
                // Top nibble indicates state
                let state = (gt_offset >> 60) & 0xF;
                if state != 0 && state != 3 {
                    // Not allocated or zero
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let gt_addr = gt_offset & 0x0FFFFFFFFFFFFFFF;
                if gt_addr == 0 {
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let grain_entry = self.read_gt_entry_64(gt_addr, gt_idx)?;
                let grain_state = (grain_entry >> 60) & 0xF;
                if grain_state != 3 {
                    // Not allocated
                    buf[..to_read].fill(0);
                    return Ok(to_read);
                }

                let grain_addr = grain_entry & 0x0FFFFFFFFFFFFFFF;
                let physical = grain_addr + in_grain;
                self.parent.read_at(physical, &mut buf[..to_read])
            }
        }
    }
}

// SAFETY: VmdkReader only holds Arc and Vec, safe to send/share
unsafe impl Send for VmdkReader {}
unsafe impl Sync for VmdkReader {}
