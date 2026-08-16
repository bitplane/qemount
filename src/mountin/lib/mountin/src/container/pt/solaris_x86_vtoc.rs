//! Solaris x86 VTOC16 container reader.

use crate::container::slice::SliceReader;
use crate::container::{invalid_data, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const SECTOR_SIZE: u64 = 512;
const LABEL_OFFSET: u64 = SECTOR_SIZE;
const VTOC_SANITY: u32 = 0x600D_DEEE;
const VTOC_MAGIC: u16 = 0xDABE;
const VTOC_PARTITIONS: usize = 16;
const RAW_SLICE: usize = 2;
const PARTITION_COUNT_OFFSET: u64 = 30;
const PARTITION_TABLE_OFFSET: u64 = 72;
const PARTITION_ENTRY_SIZE: u64 = 12;

pub struct SolarisX86VtocContainer;

pub static SOLARIS_X86_VTOC: SolarisX86VtocContainer = SolarisX86VtocContainer;

impl Container for SolarisX86VtocContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        if read_le32(&*reader, LABEL_OFFSET + 12)? != VTOC_SANITY
            || read_le16(&*reader, LABEL_OFFSET + 508)? != VTOC_MAGIC
        {
            return Err(invalid_data("invalid Solaris x86 VTOC label"));
        }
        if read_le16(&*reader, LABEL_OFFSET + PARTITION_COUNT_OFFSET)? as usize
            != VTOC_PARTITIONS
        {
            return Err(invalid_data("invalid Solaris x86 VTOC slice count"));
        }

        let parent_size = reader.size();
        let mut children = Vec::new();
        for index in 0..VTOC_PARTITIONS {
            if index == RAW_SLICE {
                continue;
            }
            let entry = LABEL_OFFSET + PARTITION_TABLE_OFFSET + index as u64 * PARTITION_ENTRY_SIZE;
            let start_sector = read_le32(&*reader, entry + 4)? as u64;
            let sector_count = read_le32(&*reader, entry + 8)? as u64;
            if sector_count == 0 {
                continue;
            }

            let start = start_sector
                .checked_mul(SECTOR_SIZE)
                .ok_or_else(|| invalid_data("Solaris x86 VTOC slice offset overflow"))?;
            let length = sector_count
                .checked_mul(SECTOR_SIZE)
                .ok_or_else(|| invalid_data("Solaris x86 VTOC slice length overflow"))?;
            let end = start
                .checked_add(length)
                .ok_or_else(|| invalid_data("Solaris x86 VTOC slice end overflow"))?;
            if parent_size.is_some_and(|size| end > size) {
                return Err(invalid_data("Solaris x86 VTOC slice extends past image"));
            }

            children.push(Child {
                index: index as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        if children.is_empty() {
            return Err(invalid_data("empty Solaris x86 VTOC"));
        }
        Ok(children)
    }
}

fn read_le16(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut bytes = [0; 2];
    if reader.read_at(offset, &mut bytes)? != bytes.len() {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u16::from_le_bytes(bytes))
}

fn read_le32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut bytes = [0; 4];
    if reader.read_at(offset, &mut bytes)? != bytes.len() {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_le_bytes(bytes))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::container::BytesReader;

    fn image(start: u32, size: u32, image_sectors: usize) -> Arc<BytesReader> {
        let mut bytes = vec![0; image_sectors * SECTOR_SIZE as usize];
        bytes[LABEL_OFFSET as usize + 12..LABEL_OFFSET as usize + 16]
            .copy_from_slice(&VTOC_SANITY.to_le_bytes());
        bytes[LABEL_OFFSET as usize + PARTITION_COUNT_OFFSET as usize
            ..LABEL_OFFSET as usize + PARTITION_COUNT_OFFSET as usize + 2]
            .copy_from_slice(&(VTOC_PARTITIONS as u16).to_le_bytes());
        bytes[LABEL_OFFSET as usize + 508..LABEL_OFFSET as usize + 510]
            .copy_from_slice(&VTOC_MAGIC.to_le_bytes());
        let entry = LABEL_OFFSET as usize + PARTITION_TABLE_OFFSET as usize;
        bytes[entry + 4..entry + 8].copy_from_slice(&start.to_le_bytes());
        bytes[entry + 8..entry + 12].copy_from_slice(&size.to_le_bytes());
        Arc::new(BytesReader::new(bytes))
    }

    #[test]
    fn exposes_vtoc_slices() {
        let children = SOLARIS_X86_VTOC.children(image(4, 8, 16)).unwrap();
        assert_eq!(children.len(), 1);
        assert_eq!(children[0].index, 0);
        assert_eq!(children[0].offset, 4 * SECTOR_SIZE);
        assert_eq!(children[0].reader.size(), Some(8 * SECTOR_SIZE));
    }

    #[test]
    fn rejects_slices_past_the_image() {
        assert!(SOLARIS_X86_VTOC.children(image(12, 8, 16)).is_err());
    }

    #[test]
    fn rejects_invalid_label() {
        let bytes = Arc::new(BytesReader::new(vec![0; 16 * SECTOR_SIZE as usize]));
        assert!(SOLARIS_X86_VTOC.children(bytes).is_err());
    }
}

