//! Container readers for recursive format detection
//!
//! Container formats (archives, compressed streams, partition tables, disk images)
//! hold other data that can be recursively detected. Container readers enumerate
//! children and provide Reader access to each.

pub mod arc;
pub mod disk;
pub mod pt;
pub mod slice;

use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Maximum size for reading container contents into memory (1 GB)
const MAX_SIZE: usize = 1024 * 1024 * 1024;

/// A child within a container
pub struct Child {
    /// Index within parent (partition number, file index, etc.)
    pub index: u32,
    /// Byte offset within parent (for slices). Ignored for transforms.
    pub offset: u64,
    /// Reader for the child's data
    pub reader: Arc<dyn Reader + Send + Sync>,
}

/// Trait for container formats that hold other detectable content
pub trait Container: Send + Sync {
    /// Enumerate children within this container
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>>;
}

/// Reader backed by in-memory bytes
pub struct BytesReader {
    data: Vec<u8>,
}

impl BytesReader {
    pub fn new(data: Vec<u8>) -> Self {
        Self { data }
    }
}

impl Reader for BytesReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        let offset = offset as usize;
        if offset >= self.data.len() {
            return Ok(0);
        }
        let available = self.data.len() - offset;
        let to_read = buf.len().min(available);
        buf[..to_read].copy_from_slice(&self.data[offset..offset + to_read]);
        Ok(to_read)
    }
}

// SAFETY: BytesReader only holds owned Vec<u8>, safe to send/share
unsafe impl Send for BytesReader {}
unsafe impl Sync for BytesReader {}

/// Read all data from a Reader into a Vec
pub fn read_all(reader: &dyn Reader) -> io::Result<Vec<u8>> {
    let mut data = Vec::new();
    let mut offset = 0u64;
    let mut buf = [0u8; 65536];

    loop {
        let n = reader.read_at(offset, &mut buf)?;
        if n == 0 {
            break;
        }
        data.extend_from_slice(&buf[..n]);
        offset += n as u64;
        if data.len() > MAX_SIZE {
            return Err(io::Error::new(
                io::ErrorKind::Other,
                "container too large",
            ));
        }
    }
    Ok(data)
}

/// Get container reader for a format, if it's a container
pub fn get_container(format: &str) -> Option<&'static dyn Container> {
    match format {
        "arc/gzip" => Some(&arc::gzip::GZIP),
        "disk/parallels" => Some(&disk::parallels::PARALLELS),
        "disk/qcow" => Some(&disk::qcow::QCOW),
        "disk/qcow2" => Some(&disk::qcow2::QCOW2),
        "disk/qed" => Some(&disk::qed::QED),
        "disk/vdi" => Some(&disk::vdi::VDI),
        "disk/vhd" => Some(&disk::vhd::VHD),
        "disk/vhdx" => Some(&disk::vhdx::VHDX),
        "disk/vmdk" => Some(&disk::vmdk::VMDK),
        "pt/apm" => Some(&pt::apm::APM),
        "pt/disklabel" => Some(&pt::disklabel::DISKLABEL),
        "pt/gpt" => Some(&pt::gpt::GPT),
        "pt/mbr" => Some(&pt::mbr::MBR),
        "pt/rdb" => Some(&pt::rdb::RDB),
        "pt/pc98" => Some(&pt::pc98::PC98),
        "pt/sgi" => Some(&pt::sgi::SGI),
        "pt/sun" => Some(&pt::sun::SUN),
        _ => None,
    }
}
