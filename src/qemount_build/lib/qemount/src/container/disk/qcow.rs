//! QCOW v1 disk image reader
//!
//! Parses QCOW format and provides virtual disk access through L1/L2 tables.

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const QCOW_MAGIC: u32 = 0x514649fb;
const QCOW_VERSION: u32 = 1;

/// QCOW disk image container
pub struct QcowContainer;

/// Static instance for registry
pub static QCOW: QcowContainer = QcowContainer;

impl Container for QcowContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let qcow_reader = QcowReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(qcow_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through QCOW L1/L2 tables
pub struct QcowReader {
    parent: Arc<dyn Reader + Send + Sync>,
    l1_table: Vec<u64>,
    cluster_size: u64,
    cluster_bits: u32,
    l2_bits: u32,
    l2_size: u64,
    virtual_size: u64,
}

impl QcowReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header (48 bytes needed)
        let mut header = [0u8; 48];
        if parent.read_at(0, &mut header)? != 48 {
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
                "invalid QCOW magic",
            ));
        }

        // Check version
        let version = u32::from_be_bytes([header[4], header[5], header[6], header[7]]);
        if version != QCOW_VERSION {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "not QCOW v1",
            ));
        }

        // Parse header fields (big-endian)
        let virtual_size = u64::from_be_bytes([
            header[24], header[25], header[26], header[27],
            header[28], header[29], header[30], header[31],
        ]);
        let cluster_bits = header[32] as u32;
        let l2_bits = header[33] as u32;
        let l1_table_offset = u64::from_be_bytes([
            header[40], header[41], header[42], header[43],
            header[44], header[45], header[46], header[47],
        ]);

        // Validate cluster_bits (9-16 typical)
        if cluster_bits < 9 || cluster_bits > 20 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid cluster_bits",
            ));
        }

        let cluster_size = 1u64 << cluster_bits;
        let l2_size = 1u64 << l2_bits;

        // Calculate L1 table size
        let l1_size = (virtual_size + (1 << (cluster_bits + l2_bits)) - 1)
            >> (cluster_bits + l2_bits);

        // Read L1 table
        let l1_bytes = l1_size as usize * 8;
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
                    chunk[0], chunk[1], chunk[2], chunk[3],
                    chunk[4], chunk[5], chunk[6], chunk[7],
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
}

impl Reader for QcowReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate indices
        let l1_index = (offset >> (self.l2_bits + self.cluster_bits)) as usize;
        let l2_index = (offset >> self.cluster_bits) & (self.l2_size - 1);
        let in_cluster = offset & (self.cluster_size - 1);

        // Check L1 bounds
        if l1_index >= self.l1_table.len() {
            // Beyond L1 table - sparse
            let to_read = buf
                .len()
                .min((self.cluster_size - in_cluster) as usize)
                .min((self.virtual_size - offset) as usize);
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // How much can we read from this cluster?
        let remaining_in_cluster = self.cluster_size - in_cluster;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_cluster as usize)
            .min(remaining_in_disk as usize);

        // Get L2 table offset from L1
        let l2_offset = self.l1_table[l1_index];
        if l2_offset == 0 {
            // Sparse L1 entry
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Read L2 entry
        let cluster_offset = self.read_l2_entry(l2_offset, l2_index)?;
        if cluster_offset == 0 {
            // Sparse cluster
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Check for compression flag (bit 63)
        if cluster_offset & (1 << 63) != 0 {
            // Compressed cluster - not supported for now
            return Err(io::Error::new(
                io::ErrorKind::Unsupported,
                "compressed QCOW clusters not supported",
            ));
        }

        // Read from physical location
        let physical_offset = cluster_offset + in_cluster;
        self.parent.read_at(physical_offset, &mut buf[..to_read])
    }
}

// SAFETY: QcowReader only holds Arc and Vec, safe to send/share
unsafe impl Send for QcowReader {}
unsafe impl Sync for QcowReader {}
