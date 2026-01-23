//! QCOW2 disk image reader
//!
//! Parses QCOW2 format and provides virtual disk access through L1/L2 tables.

use crate::container::{Child, Container};
use crate::detect::Reader;
use flate2::read::DeflateDecoder;
use std::io::{self, Read};
use std::sync::Arc;

const QCOW_MAGIC: u32 = 0x514649fb;
const L2E_OFFSET_MASK: u64 = 0x00fffffffffffe00;
const QCOW_OFLAG_COMPRESSED: u64 = 1 << 62;
const QCOW_OFLAG_ZERO: u64 = 1;

/// QCOW2 disk image container
pub struct Qcow2Container;

/// Static instance for registry
pub static QCOW2: Qcow2Container = Qcow2Container;

impl Container for Qcow2Container {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let qcow2_reader = Qcow2Reader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(qcow2_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through QCOW2 L1/L2 tables
pub struct Qcow2Reader {
    parent: Arc<dyn Reader + Send + Sync>,
    l1_table: Vec<u64>,
    cluster_size: u64,
    cluster_bits: u32,
    l2_bits: u32,
    l2_size: u64,
    virtual_size: u64,
}

impl Qcow2Reader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header (0x30 bytes needed for l1_table_offset)
        let mut header = [0u8; 0x30];
        if parent.read_at(0, &mut header)? != 0x30 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short header read",
            ));
        }

        // Check magic (big-endian)
        let magic = u32::from_be_bytes([header[0], header[1], header[2], header[3]]);
        if magic != QCOW_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid QCOW2 magic",
            ));
        }

        // Check version >= 2
        let version = u32::from_be_bytes([header[4], header[5], header[6], header[7]]);
        if version < 2 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "not QCOW2 (version < 2)",
            ));
        }

        // Parse header fields (big-endian)
        // cluster_bits: 4 bytes at offset 0x14
        let cluster_bits =
            u32::from_be_bytes([header[0x14], header[0x15], header[0x16], header[0x17]]);

        // virtual_size: 8 bytes at offset 0x18
        let virtual_size = u64::from_be_bytes([
            header[0x18],
            header[0x19],
            header[0x1a],
            header[0x1b],
            header[0x1c],
            header[0x1d],
            header[0x1e],
            header[0x1f],
        ]);

        // l1_size: 4 bytes at offset 0x24
        let l1_size =
            u32::from_be_bytes([header[0x24], header[0x25], header[0x26], header[0x27]]) as usize;

        // l1_table_offset: 8 bytes at offset 0x28
        let l1_table_offset = u64::from_be_bytes([
            header[0x28],
            header[0x29],
            header[0x2a],
            header[0x2b],
            header[0x2c],
            header[0x2d],
            header[0x2e],
            header[0x2f],
        ]);

        // Validate cluster_bits (9-21 typical)
        if cluster_bits < 9 || cluster_bits > 21 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid cluster_bits",
            ));
        }

        let cluster_size = 1u64 << cluster_bits;
        // l2_bits = cluster_bits - 3 (each L2 entry is 8 bytes)
        let l2_bits = cluster_bits - 3;
        let l2_size = 1u64 << l2_bits;

        // Read L1 table
        let l1_bytes = l1_size * 8;
        let mut l1_data = vec![0u8; l1_bytes];
        if parent.read_at(l1_table_offset, &mut l1_data)? != l1_bytes {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short L1 table read",
            ));
        }

        // Parse L1 table (big-endian u64)
        let l1_table: Vec<u64> = l1_data
            .chunks_exact(8)
            .map(|chunk| {
                u64::from_be_bytes([
                    chunk[0], chunk[1], chunk[2], chunk[3], chunk[4], chunk[5], chunk[6], chunk[7],
                ])
            })
            .collect();

        Ok(Self {
            parent,
            l1_table,
            cluster_size,
            cluster_bits,
            l2_bits,
            l2_size,
            virtual_size,
        })
    }

    fn read_l2_entry(&self, l2_offset: u64, l2_index: u64) -> io::Result<u64> {
        let mut buf = [0u8; 8];
        let offset = l2_offset + l2_index * 8;
        if self.parent.read_at(offset, &mut buf)? != 8 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short L2 read",
            ));
        }
        Ok(u64::from_be_bytes(buf))
    }

    fn read_compressed_cluster(&self, l2_entry: u64) -> io::Result<Vec<u8>> {
        // Compressed cluster encoding:
        // - Lower (63 - cluster_bits) bits: host offset
        // - Next cluster_bits bits: (nb_sectors - 1)
        let csize_shift = 63 - self.cluster_bits;
        let coffset_mask = (1u64 << csize_shift) - 1;
        let csize_mask = (1u64 << self.cluster_bits) - 1;

        let coffset = l2_entry & coffset_mask;
        let nb_sectors = ((l2_entry >> csize_shift) & csize_mask) + 1;
        let compressed_size = nb_sectors as usize * 512;

        // Read compressed data
        let mut compressed = vec![0u8; compressed_size];
        let n = self.parent.read_at(coffset, &mut compressed)?;
        compressed.truncate(n);

        // Decompress (QCOW2 uses raw deflate)
        let mut decoder = DeflateDecoder::new(&compressed[..]);
        let mut decompressed = vec![0u8; self.cluster_size as usize];
        decoder.read_exact(&mut decompressed)?;

        Ok(decompressed)
    }
}

impl Reader for Qcow2Reader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate indices
        let l1_index = (offset >> (self.l2_bits + self.cluster_bits)) as usize;
        let l2_index = (offset >> self.cluster_bits) & (self.l2_size - 1);
        let in_cluster = offset & (self.cluster_size - 1);

        // How much can we read from this cluster?
        let remaining_in_cluster = self.cluster_size - in_cluster;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_cluster as usize)
            .min(remaining_in_disk as usize);

        // Check L1 bounds
        if l1_index >= self.l1_table.len() {
            // Beyond L1 table - sparse
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Get L2 table offset from L1 (apply mask)
        let l1_entry = self.l1_table[l1_index];
        let l2_offset = l1_entry & L2E_OFFSET_MASK;
        if l2_offset == 0 {
            // Sparse L1 entry
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Read L2 entry
        let l2_entry = self.read_l2_entry(l2_offset, l2_index)?;

        // Check for zero flag (bit 0)
        if l2_entry & QCOW_OFLAG_ZERO != 0 {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Extract cluster offset (apply mask)
        let cluster_offset = l2_entry & L2E_OFFSET_MASK;
        if cluster_offset == 0 {
            // Sparse cluster
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Check for compression flag (bit 62)
        if l2_entry & QCOW_OFLAG_COMPRESSED != 0 {
            let decompressed = self.read_compressed_cluster(l2_entry)?;
            buf[..to_read].copy_from_slice(&decompressed[in_cluster as usize..][..to_read]);
            return Ok(to_read);
        }

        // Read from physical location
        let physical_offset = cluster_offset + in_cluster;
        self.parent.read_at(physical_offset, &mut buf[..to_read])
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: Qcow2Reader only holds Arc and Vec, safe to send/share
unsafe impl Send for Qcow2Reader {}
unsafe impl Sync for Qcow2Reader {}
