//! QED (QEMU Enhanced Disk) image reader
//!
//! Parses QED format and provides virtual disk access through L1/L2 tables.

use crate::container::{checked_table_size, invalid_data, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const QED_MAGIC: u32 = 0x00444551;
const QED_MIN_CLUSTER_SIZE: u64 = 4 * 1024;
const QED_MAX_CLUSTER_SIZE: u64 = 64 * 1024 * 1024;
const QED_MAX_TABLE_SIZE: u64 = 16;

/// QED disk image container
pub struct QedContainer;

/// Static instance for registry
pub static QED: QedContainer = QedContainer;

impl Container for QedContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let qed_reader = QedReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(qed_reader),
        }])
    }
}

/// Reader that translates virtual disk offsets through QED L1/L2 tables
pub struct QedReader {
    parent: Arc<dyn Reader + Send + Sync>,
    l1_table: Vec<u64>,
    cluster_size: u64,
    l2_entries: u64,
    virtual_size: u64,
}

impl QedReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Read header (0x38 bytes needed)
        let mut header = [0u8; 0x38];
        if parent.read_at(0, &mut header)? != 0x38 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short header read",
            ));
        }

        // Check magic (little-endian)
        let magic = u32::from_le_bytes([header[0], header[1], header[2], header[3]]);
        if magic != QED_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid QED magic",
            ));
        }

        // Parse header fields (little-endian)
        let cluster_size =
            u32::from_le_bytes([header[0x04], header[0x05], header[0x06], header[0x07]]) as u64;
        let table_size =
            u32::from_le_bytes([header[0x08], header[0x09], header[0x0a], header[0x0b]]) as u64;
        let l1_table_offset = u64::from_le_bytes([
            header[0x28],
            header[0x29],
            header[0x2a],
            header[0x2b],
            header[0x2c],
            header[0x2d],
            header[0x2e],
            header[0x2f],
        ]);
        let virtual_size = u64::from_le_bytes([
            header[0x30],
            header[0x31],
            header[0x32],
            header[0x33],
            header[0x34],
            header[0x35],
            header[0x36],
            header[0x37],
        ]);

        // QED stores table_size in clusters; both fields are powers of two.
        if !(QED_MIN_CLUSTER_SIZE..=QED_MAX_CLUSTER_SIZE).contains(&cluster_size)
            || !cluster_size.is_power_of_two()
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid cluster_size",
            ));
        }
        if table_size == 0 || table_size > QED_MAX_TABLE_SIZE || !table_size.is_power_of_two() {
            return Err(invalid_data("invalid QED table_size"));
        }

        // L1/L2 table entries = (table_size * cluster_size) / 8
        let l1_bytes_u64 = table_size
            .checked_mul(cluster_size)
            .ok_or_else(|| invalid_data("QED table size overflow"))?;
        let l2_entries = l1_bytes_u64 / 8;

        // Read L1 table
        let l1_bytes = checked_table_size(parent.as_ref(), l1_table_offset, l2_entries, 8)?;
        let mut l1_data = vec![0u8; l1_bytes];
        if parent.read_at(l1_table_offset, &mut l1_data)? != l1_bytes {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short L1 table read",
            ));
        }

        // Parse L1 table (little-endian u64)
        let l1_table: Vec<u64> = l1_data
            .chunks_exact(8)
            .map(|chunk| {
                u64::from_le_bytes([
                    chunk[0], chunk[1], chunk[2], chunk[3], chunk[4], chunk[5], chunk[6], chunk[7],
                ])
            })
            .collect();

        Ok(Self {
            parent,
            l1_table,
            cluster_size,
            l2_entries,
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
        Ok(u64::from_le_bytes(buf))
    }
}

impl Reader for QedReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate indices
        // Each L2 table covers (l2_entries * cluster_size) bytes
        let l2_coverage = self.l2_entries * self.cluster_size;
        let l1_index = (offset / l2_coverage) as usize;
        let l2_index = (offset % l2_coverage) / self.cluster_size;
        let in_cluster = offset % self.cluster_size;

        // How much can we read from this cluster?
        let remaining_in_cluster = self.cluster_size - in_cluster;
        let remaining_in_disk = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_cluster as usize)
            .min(remaining_in_disk as usize);

        // Check L1 bounds
        if l1_index >= self.l1_table.len() {
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Get L2 table offset from L1
        let l2_offset = self.l1_table[l1_index];
        if l2_offset == 0 {
            // Sparse L1 entry
            buf[..to_read].fill(0);
            return Ok(to_read);
        }

        // Read L2 entry
        let cluster_offset = self.read_l2_entry(l2_offset, l2_index)?;

        // Check for unallocated (0) or zero cluster (1)
        if cluster_offset <= 1 {
            buf[..to_read].fill(0);
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

// SAFETY: QedReader only holds Arc and Vec, safe to send/share
unsafe impl Send for QedReader {}
unsafe impl Sync for QedReader {}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::container::BytesReader;

    fn header(cluster_size: u32, table_size: u32) -> Vec<u8> {
        let mut data = vec![0u8; 0x38];
        data[0..4].copy_from_slice(&QED_MAGIC.to_le_bytes());
        data[0x04..0x08].copy_from_slice(&cluster_size.to_le_bytes());
        data[0x08..0x0c].copy_from_slice(&table_size.to_le_bytes());
        data
    }

    #[test]
    fn rejects_zero_table_size() {
        let image = Arc::new(BytesReader::new(header(4096, 0)));
        assert!(QedReader::new(image).is_err());
    }

    #[test]
    fn rejects_table_larger_than_image() {
        let image = Arc::new(BytesReader::new(header(4096, 1)));
        assert!(QedReader::new(image).is_err());
    }
}
