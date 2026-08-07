//! Plan 9 textual partition table container reader.

use crate::container::slice::SliceReader;
use crate::container::{invalid_data, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const SECTOR_SIZE: u64 = 512;
const TABLE_OFFSET: u64 = SECTOR_SIZE;
const MAX_PARTITIONS: usize = 32;

pub struct Plan9Container;

pub static PLAN9: Plan9Container = Plan9Container;

impl Container for Plan9Container {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let mut table = [0u8; SECTOR_SIZE as usize];
        if reader.read_at(TABLE_OFFSET, &mut table)? != table.len() {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short Plan 9 partition table",
            ));
        }

        let end = table
            .iter()
            .position(|&byte| byte == 0)
            .unwrap_or(table.len());
        let text = std::str::from_utf8(&table[..end])
            .map_err(|_| invalid_data("Plan 9 partition table is not ASCII"))?;
        let parent_size = reader.size();
        let mut children = Vec::new();

        for line in text.lines().filter(|line| !line.trim().is_empty()) {
            if children.len() == MAX_PARTITIONS {
                return Err(invalid_data("too many Plan 9 partitions"));
            }

            let fields: Vec<_> = line.split_whitespace().collect();
            if fields.len() != 4 || fields[0] != "part" {
                return Err(invalid_data("invalid Plan 9 partition entry"));
            }

            let start_sector = parse_sector(fields[2])?;
            let end_sector = parse_sector(fields[3])?;
            if start_sector >= end_sector {
                return Err(invalid_data("invalid Plan 9 partition extent"));
            }

            let start = start_sector
                .checked_mul(SECTOR_SIZE)
                .ok_or_else(|| invalid_data("Plan 9 partition offset overflow"))?;
            let end = end_sector
                .checked_mul(SECTOR_SIZE)
                .ok_or_else(|| invalid_data("Plan 9 partition end overflow"))?;
            if parent_size.is_some_and(|size| end > size) {
                return Err(invalid_data("Plan 9 partition extends past image"));
            }

            children.push(Child {
                index: children.len() as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, end - start)),
            });
        }

        if children.is_empty() {
            return Err(invalid_data("empty Plan 9 partition table"));
        }
        Ok(children)
    }
}

fn parse_sector(value: &str) -> io::Result<u64> {
    value
        .parse()
        .map_err(|_| invalid_data("invalid Plan 9 partition sector"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::container::BytesReader;

    fn image(table: &[u8], sectors: usize) -> Arc<BytesReader> {
        let mut image = vec![0; sectors * SECTOR_SIZE as usize];
        image[SECTOR_SIZE as usize..SECTOR_SIZE as usize + table.len()].copy_from_slice(table);
        Arc::new(BytesReader::new(image))
    }

    #[test]
    fn parses_partition_extents() {
        let children = PLAN9
            .children(image(b"part fs 2 6\npart swap 6 8\n", 8))
            .unwrap();

        assert_eq!(children.len(), 2);
        assert_eq!(children[0].index, 0);
        assert_eq!(children[0].offset, 2 * SECTOR_SIZE);
        assert_eq!(children[0].reader.size(), Some(4 * SECTOR_SIZE));
        assert_eq!(children[1].index, 1);
        assert_eq!(children[1].offset, 6 * SECTOR_SIZE);
        assert_eq!(children[1].reader.size(), Some(2 * SECTOR_SIZE));
    }

    #[test]
    fn rejects_malformed_entries() {
        assert!(PLAN9.children(image(b"part fs two 6\n", 8)).is_err());
        assert!(PLAN9.children(image(b"part fs 6 2\n", 8)).is_err());
        assert!(PLAN9.children(image(b"part fs 2 9\n", 8)).is_err());
    }
}
