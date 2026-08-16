//! APRIDISK (ACT Apricot disk image) container reader
//!
//! APRIDISK is a self-describing container for ACT Apricot floppies. Instead of
//! storing tracks at fixed offsets it holds a sequence of typed records: sector
//! records (raw or run-length compressed) plus optional comment and creator
//! metadata. This reconstructs a flat raw sector image by placing each sector
//! at its CHS position, which the recursion engine can then detect (Apricots
//! ran MS-DOS, so the payload is typically FAT).
//!
//! Format reference: docs/format/disk/apridisk.md
//! MAME loader: src/lib/formats/apridisk.{cpp,h}

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

// ---- APRIDISK layout ----

/// File signature: ASCII text followed by 0x1A 0x04.
const MAGIC: &[u8] = b"ACT Apricot disk image\x1a\x04";
/// Fixed header size; records begin immediately after.
const HEADER_SIZE: usize = 128;
/// Minimum bytes of a record header before the payload.
const RECORD_HEADER_SIZE: usize = 16;
const SECTOR_SIZE: usize = 512;
/// Apricot HD ceiling (80 tracks x 2 heads x 18 sectors); bounds allocation.
const MAX_SECTORS: usize = 2880;

// Record type tags (little-endian u32).
const APR_SECTOR: u32 = 0xe31d_0001;

// Compression modes (little-endian u16).
const APR_UNCOMPRESSED: u16 = 0x9e90;
const APR_COMPRESSED: u16 = 0x3e5a;

// Defensive geometry caps for corrupt input.
const MAX_TRACK: u16 = 159;
const MAX_HEAD: u8 = 1;
const MAX_SECTOR: u8 = 64;

fn invalid(msg: &str) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, msg)
}

fn le16(b: &[u8], o: usize) -> u16 {
    u16::from_le_bytes([b[o], b[o + 1]])
}

fn le32(b: &[u8], o: usize) -> u32 {
    u32::from_le_bytes([b[o], b[o + 1], b[o + 2], b[o + 3]])
}

struct SectorRec {
    track: u16,
    head: u8,
    sector: u8, // 1-based, as stored
    data: Vec<u8>,
}

/// Reconstruct a flat raw sector image from APRIDISK bytes.
fn reconstruct(data: &[u8]) -> io::Result<Vec<u8>> {
    if data.len() < HEADER_SIZE || &data[..MAGIC.len()] != MAGIC {
        return Err(invalid("not an APRIDISK image"));
    }

    let mut recs: Vec<SectorRec> = Vec::new();
    let mut max_track: u16 = 0;
    let mut max_head: u8 = 0;
    let mut max_sector: u8 = 0;

    let mut off = HEADER_SIZE;
    while off + RECORD_HEADER_SIZE <= data.len() {
        let rtype = le32(data, off);
        let compression = le16(data, off + 4);
        let header_size = le16(data, off + 6) as usize;
        let data_size = le32(data, off + 8) as usize;

        if header_size < RECORD_HEADER_SIZE {
            return Err(invalid("APRIDISK record header too small"));
        }
        let payload_off = off
            .checked_add(header_size)
            .ok_or_else(|| invalid("APRIDISK record offset overflow"))?;
        let next = payload_off
            .checked_add(data_size)
            .ok_or_else(|| invalid("APRIDISK record offset overflow"))?;
        if next > data.len() {
            return Err(invalid("APRIDISK record runs past end of file"));
        }

        if rtype == APR_SECTOR {
            let head = data[off + 12];
            let sector = data[off + 13];
            let track = le16(data, off + 14);
            if track > MAX_TRACK || head > MAX_HEAD || sector == 0 || sector > MAX_SECTOR {
                return Err(invalid("APRIDISK sector geometry out of range"));
            }

            let payload = &data[payload_off..next];
            let sec = match compression {
                APR_UNCOMPRESSED => {
                    if payload.len() < SECTOR_SIZE {
                        return Err(invalid("APRIDISK uncompressed sector too short"));
                    }
                    payload[..SECTOR_SIZE].to_vec()
                }
                APR_COMPRESSED => {
                    // RLE: u16 length + fill byte; a sector is one repeated byte.
                    if payload.len() < 3 {
                        return Err(invalid("APRIDISK compressed sector too short"));
                    }
                    let count = le16(payload, 0) as usize;
                    if count != SECTOR_SIZE {
                        return Err(invalid("APRIDISK compressed length != sector size"));
                    }
                    vec![payload[2]; SECTOR_SIZE]
                }
                _ => return Err(invalid("APRIDISK unknown compression mode")),
            };

            max_track = max_track.max(track);
            max_head = max_head.max(head);
            max_sector = max_sector.max(sector);
            recs.push(SectorRec {
                track,
                head,
                sector,
                data: sec,
            });
            if recs.len() > MAX_SECTORS {
                return Err(invalid("APRIDISK sector count exceeds maximum"));
            }
        }
        // Comment / creator / deleted records are skipped.

        let advance = header_size + data_size;
        if advance == 0 {
            break; // guard against a zero-length record stalling the scan
        }
        off += advance;
    }

    if recs.is_empty() {
        return Err(invalid("APRIDISK contains no sector records"));
    }

    // Derive geometry from the records; sectors are 1-based so the highest
    // sector number is the per-track count. CHS -> LBA is the standard PC
    // interleave: ((track * heads + head) * spt + (sector - 1)).
    let heads = max_head as usize + 1;
    let spt = max_sector as usize;
    let tracks = max_track as usize + 1;
    let total_sectors = tracks * heads * spt;
    if total_sectors == 0 || total_sectors > MAX_SECTORS {
        return Err(invalid("APRIDISK geometry exceeds maximum disk size"));
    }

    let mut img = vec![0u8; total_sectors * SECTOR_SIZE];
    for r in &recs {
        let lba =
            (r.track as usize * heads + r.head as usize) * spt + (r.sector as usize - 1);
        let off = lba * SECTOR_SIZE;
        img[off..off + SECTOR_SIZE].copy_from_slice(&r.data);
    }

    Ok(img)
}

// ---- Container implementation ----

pub struct ApridiskContainer;

pub static APRIDISK: ApridiskContainer = ApridiskContainer;

impl Container for ApridiskContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let data = read_all(&*reader)?;
        let img = reconstruct(&data)?;
        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // reconstructed data, not a slice of the parent
            reader: Arc::new(BytesReader::new(img)),
        }])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn header() -> Vec<u8> {
        let mut h = vec![0u8; HEADER_SIZE];
        h[..MAGIC.len()].copy_from_slice(MAGIC);
        h
    }

    fn raw_sector(track: u16, head: u8, sector: u8, fill: u8) -> Vec<u8> {
        let mut r = vec![0u8; RECORD_HEADER_SIZE];
        r[0..4].copy_from_slice(&APR_SECTOR.to_le_bytes());
        r[4..6].copy_from_slice(&APR_UNCOMPRESSED.to_le_bytes());
        r[6..8].copy_from_slice(&(RECORD_HEADER_SIZE as u16).to_le_bytes());
        r[8..12].copy_from_slice(&(SECTOR_SIZE as u32).to_le_bytes());
        r[12] = head;
        r[13] = sector;
        r[14..16].copy_from_slice(&track.to_le_bytes());
        r.extend_from_slice(&vec![fill; SECTOR_SIZE]);
        r
    }

    fn rle_sector(track: u16, head: u8, sector: u8, fill: u8) -> Vec<u8> {
        let mut r = vec![0u8; RECORD_HEADER_SIZE];
        r[0..4].copy_from_slice(&APR_SECTOR.to_le_bytes());
        r[4..6].copy_from_slice(&APR_COMPRESSED.to_le_bytes());
        r[6..8].copy_from_slice(&(RECORD_HEADER_SIZE as u16).to_le_bytes());
        r[8..12].copy_from_slice(&3u32.to_le_bytes());
        r[12] = head;
        r[13] = sector;
        r[14..16].copy_from_slice(&track.to_le_bytes());
        r.extend_from_slice(&(SECTOR_SIZE as u16).to_le_bytes());
        r.push(fill);
        r
    }

    /// A 1-track, 2-head, 2-sector-per-track disk: 4 sectors total.
    fn sample() -> Vec<u8> {
        let mut a = header();
        a.extend(raw_sector(0, 0, 1, 0xAA)); // lba 0
        a.extend(rle_sector(0, 0, 2, 0xBB)); // lba 1
        a.extend(raw_sector(0, 1, 1, 0xCC)); // lba 2
        a.extend(raw_sector(0, 1, 2, 0xDD)); // lba 3
        a
    }

    #[test]
    fn reconstructs_chs_layout() {
        let img = reconstruct(&sample()).unwrap();
        // heads=2, spt=2, tracks=1 -> 4 sectors
        assert_eq!(img.len(), 4 * SECTOR_SIZE);
        assert_eq!(img[0 * SECTOR_SIZE], 0xAA);
        assert_eq!(img[1 * SECTOR_SIZE], 0xBB); // RLE-expanded
        assert_eq!(img[2 * SECTOR_SIZE], 0xCC);
        assert_eq!(img[3 * SECTOR_SIZE], 0xDD);
        // RLE sector is uniformly the fill byte
        assert!(img[SECTOR_SIZE..2 * SECTOR_SIZE].iter().all(|&b| b == 0xBB));
    }

    #[test]
    fn missing_sectors_zero_filled() {
        // Only lba 0 and lba 3 present; 1 and 2 must be zero.
        let mut a = header();
        a.extend(raw_sector(0, 0, 1, 0x11));
        a.extend(raw_sector(0, 1, 2, 0x44));
        let img = reconstruct(&a).unwrap();
        assert_eq!(img.len(), 4 * SECTOR_SIZE);
        assert_eq!(img[0], 0x11);
        assert!(img[SECTOR_SIZE..3 * SECTOR_SIZE].iter().all(|&b| b == 0));
        assert_eq!(img[3 * SECTOR_SIZE], 0x44);
    }

    #[test]
    fn skips_comment_records() {
        let mut a = header();
        // A comment record (type 0xe31d0002) between sectors must be ignored.
        let mut comment = vec![0u8; RECORD_HEADER_SIZE];
        comment[0..4].copy_from_slice(&0xe31d_0002u32.to_le_bytes());
        comment[6..8].copy_from_slice(&(RECORD_HEADER_SIZE as u16).to_le_bytes());
        comment[8..12].copy_from_slice(&5u32.to_le_bytes());
        comment.extend_from_slice(b"hello");
        a.extend(raw_sector(0, 0, 1, 0xAA));
        a.extend(comment);
        a.extend(raw_sector(0, 0, 2, 0xBB));
        let img = reconstruct(&a).unwrap();
        assert_eq!(img.len(), 2 * SECTOR_SIZE);
        assert_eq!(img[0], 0xAA);
        assert_eq!(img[SECTOR_SIZE], 0xBB);
    }

    #[test]
    fn rejects_bad_magic() {
        let mut bad = sample();
        bad[0] = b'X';
        assert!(reconstruct(&bad).is_err());
    }

    #[test]
    fn rejects_truncated_record() {
        let mut short = sample();
        short.truncate(short.len() - SECTOR_SIZE); // chop last sector payload
        assert!(reconstruct(&short).is_err());
    }

    #[test]
    fn rejects_no_sectors() {
        assert!(reconstruct(&header()).is_err());
    }

    /// The registry must dispatch "disk/apridisk" to this container and unwrap
    /// to exactly one reconstructed child.
    #[test]
    fn registry_unwraps_one_child() {
        let container =
            crate::container::get_container("disk/apridisk").expect("disk/apridisk not registered");
        let reader = Arc::new(BytesReader::new(sample()));
        let children = container.children(reader).unwrap();
        assert_eq!(children.len(), 1);
    }
}
