//! SCL (Sinclair TR-DOS) disk image reader
//!
//! Reconstructs a raw TRD disk image from an SCL container. SCL stores only the
//! TR-DOS catalogue entries and the sectors each file actually uses; this
//! expands them back onto an otherwise-empty 640K DS80 disk, which is what
//! TR-DOS tooling and emulators expect.
//!
//! Format reference: docs/format/disk/scl.md

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

// ---- SCL layout ----

const SCL_MAGIC: &[u8; 8] = b"SINCLAIR";
const SCL_HEADER_LEN: usize = 9; // magic (8) + file count (1)
const SCL_ENTRY_LEN: usize = 14; // catalogue entry without start sector/track

// ---- TRD (DS80) geometry ----

const SECTOR: usize = 256;
const SECTORS_PER_TRACK: usize = 16;
const LOGICAL_TRACKS: usize = 160; // 80 cylinders x 2 sides
const TRD_SIZE: usize = LOGICAL_TRACKS * SECTORS_PER_TRACK * SECTOR; // 655360

const MAX_FILES: usize = 128; // catalogue is 8 sectors x 16 entries
const CATALOG_ENTRY_LEN: usize = 16; // TRD entry: SCL entry + start sector + track
const SYSTEM_SECTOR: usize = 8; // track 0, sector 8 holds the disk spec
const DATA_START_SECTOR: usize = SECTORS_PER_TRACK; // files begin at track 1
const FREE_SECTORS_TOTAL: usize = LOGICAL_TRACKS * SECTORS_PER_TRACK - SECTORS_PER_TRACK; // 2544

const DISK_TYPE_DS80: u8 = 0x16;
const TRDOS_ID: u8 = 0x10;

fn invalid(msg: &str) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, msg)
}

/// Reconstruct a raw TRD image from SCL bytes.
fn reconstruct_trd(data: &[u8]) -> io::Result<Vec<u8>> {
    if data.len() < SCL_HEADER_LEN || &data[..8] != SCL_MAGIC {
        return Err(invalid("not an SCL image"));
    }

    let count = data[8] as usize;
    if count > MAX_FILES {
        return Err(invalid("SCL file count exceeds 128"));
    }

    let dir_end = SCL_HEADER_LEN + count * SCL_ENTRY_LEN;
    if data.len() < dir_end {
        return Err(invalid("SCL truncated in catalogue"));
    }

    let mut trd = vec![0u8; TRD_SIZE];

    let mut data_pos = dir_end; // read cursor over SCL file data
    let mut next_sector = DATA_START_SECTOR; // linear sector index in the TRD
    let mut used_sectors = 0usize;

    for i in 0..count {
        let entry = &data[SCL_HEADER_LEN + i * SCL_ENTRY_LEN..][..SCL_ENTRY_LEN];
        let sectors = entry[13] as usize;
        let nbytes = sectors * SECTOR;

        if data_pos + nbytes > data.len() {
            return Err(invalid("SCL truncated in file data"));
        }
        if next_sector + sectors > LOGICAL_TRACKS * SECTORS_PER_TRACK {
            return Err(invalid("SCL contents overflow TRD disk"));
        }

        // Lay the file's sectors down contiguously.
        let trd_off = next_sector * SECTOR;
        trd[trd_off..trd_off + nbytes].copy_from_slice(&data[data_pos..data_pos + nbytes]);

        // Catalogue entry in track 0: the 14 SCL bytes plus the placement.
        let cat_off = i * CATALOG_ENTRY_LEN;
        trd[cat_off..cat_off + SCL_ENTRY_LEN].copy_from_slice(entry);
        trd[cat_off + 14] = (next_sector % SECTORS_PER_TRACK) as u8;
        trd[cat_off + 15] = (next_sector / SECTORS_PER_TRACK) as u8;

        data_pos += nbytes;
        next_sector += sectors;
        used_sectors += sectors;
    }

    if used_sectors > FREE_SECTORS_TOTAL {
        return Err(invalid("SCL contents overflow TRD disk"));
    }

    // Disk specification (track 0, sector 8). Offsets are TR-DOS conventions.
    let sys = SYSTEM_SECTOR * SECTOR;
    let free = FREE_SECTORS_TOTAL - used_sectors;
    trd[sys + 0xE1] = (next_sector % SECTORS_PER_TRACK) as u8; // first free sector
    trd[sys + 0xE2] = (next_sector / SECTORS_PER_TRACK) as u8; // first free track
    trd[sys + 0xE3] = DISK_TYPE_DS80;
    trd[sys + 0xE4] = count as u8;
    trd[sys + 0xE5] = (free & 0xFF) as u8;
    trd[sys + 0xE6] = ((free >> 8) & 0xFF) as u8;
    trd[sys + 0xE7] = TRDOS_ID;
    trd[sys + 0xF4] = 0; // deleted files
    for b in &mut trd[sys + 0xF5..sys + 0xFD] {
        *b = b' '; // 8-char disk label, left blank
    }

    Ok(trd)
}

// ---- Container implementation ----

pub struct SclContainer;

pub static SCL: SclContainer = SclContainer;

impl Container for SclContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let data = read_all(&*reader)?;
        let trd = reconstruct_trd(&data)?;
        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // reconstructed data, not a slice of the parent
            reader: Arc::new(BytesReader::new(trd)),
        }])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Build a tiny SCL: two one-sector "Code" files.
    fn sample_scl() -> Vec<u8> {
        let mut scl = Vec::new();
        scl.extend_from_slice(SCL_MAGIC);
        scl.push(2); // file count

        // entry: 8-char name, type, param1, length, sectors
        let mut entry = |name: &[u8; 8], sectors: u8| {
            scl.extend_from_slice(name);
            scl.push(b'C');
            scl.extend_from_slice(&0x8000u16.to_le_bytes());
            scl.extend_from_slice(&0u16.to_le_bytes());
            scl.push(sectors);
        };
        entry(b"FIRST   ", 1);
        entry(b"SECOND  ", 1);

        // data: one sector each
        scl.extend_from_slice(&[0xAA; SECTOR]);
        scl.extend_from_slice(&[0xBB; SECTOR]);
        scl
    }

    #[test]
    fn reconstructs_ds80_geometry() {
        let trd = reconstruct_trd(&sample_scl()).unwrap();
        assert_eq!(trd.len(), TRD_SIZE);

        let sys = SYSTEM_SECTOR * SECTOR;
        assert_eq!(trd[sys + 0xE3], DISK_TYPE_DS80);
        assert_eq!(trd[sys + 0xE7], TRDOS_ID);
        assert_eq!(trd[sys + 0xE4], 2); // file count
        // two sectors used -> 2542 free
        let free = u16::from_le_bytes([trd[sys + 0xE5], trd[sys + 0xE6]]);
        assert_eq!(free as usize, FREE_SECTORS_TOTAL - 2);
        // first free is track 1, sector 2
        assert_eq!(trd[sys + 0xE2], 1);
        assert_eq!(trd[sys + 0xE1], 2);
    }

    #[test]
    fn places_files_at_track_one() {
        let trd = reconstruct_trd(&sample_scl()).unwrap();
        // catalogue entry 0 points at track 1, sector 0
        assert_eq!(&trd[0..8], b"FIRST   ");
        assert_eq!(trd[14], 0); // start sector
        assert_eq!(trd[15], 1); // start track
        // file data laid down at track 1 sector 0 and sector 1
        let base = DATA_START_SECTOR * SECTOR;
        assert_eq!(trd[base], 0xAA);
        assert_eq!(trd[base + SECTOR], 0xBB);
    }

    #[test]
    fn rejects_bad_magic() {
        let mut bad = sample_scl();
        bad[0] = b'X';
        assert!(reconstruct_trd(&bad).is_err());
    }

    #[test]
    fn rejects_truncated_data() {
        let mut short = sample_scl();
        short.truncate(short.len() - SECTOR); // drop a data sector
        assert!(reconstruct_trd(&short).is_err());
    }

    /// Full registry path: the SINCLAIR magic rule must dispatch to this
    /// container and unwrap to exactly one reconstructed TRD child.
    #[test]
    fn detect_chain_unwraps_to_trd() {
        let reader = Arc::new(BytesReader::new(sample_scl()));
        let tree = crate::detect::detect_tree(reader);
        let scl = tree
            .iter()
            .find(|n| n.format.to_str() == Ok("disk/scl"))
            .expect("disk/scl not detected");
        assert_eq!(scl.children.len(), 1, "expected one TRD child");
    }
}
