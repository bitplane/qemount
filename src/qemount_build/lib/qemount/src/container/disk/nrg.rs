//! NRG (Nero Burning ROM) disc image reader
//!
//! Parses NRG format and exposes data tracks for filesystem detection.
//! Based on libmirage NRG parser.

use crate::container::{slice::SliceReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// NRG disc image container
pub struct NrgContainer;

/// Static instance for registry
pub static NRG: NrgContainer = NrgContainer;

/// Track mode
#[derive(Debug, Clone, Copy, PartialEq)]
enum TrackMode {
    Mode1,      // 2048 bytes
    Mode2,      // 2336 bytes
    Mode2Xa1,   // 2048 bytes (XA Form 1)
    Mode2Raw,   // 2352 bytes
    Audio,      // 2352 bytes
    Mode1Raw,   // 2352 bytes
    Mode2Xa1Raw, // 2352 bytes
    Mode2Xa2Raw, // 2352 bytes
}

impl TrackMode {
    fn from_code(code: u8) -> Option<Self> {
        match code {
            0x00 => Some(TrackMode::Mode1),
            0x02 => Some(TrackMode::Mode2),
            0x03 => Some(TrackMode::Mode2Xa1),
            0x06 => Some(TrackMode::Mode2Raw),
            0x07 => Some(TrackMode::Audio),
            0x0F => Some(TrackMode::Mode1Raw),
            0x10 => Some(TrackMode::Mode2Xa1Raw),
            0x11 => Some(TrackMode::Mode2Xa2Raw),
            _ => None,
        }
    }
}

/// Parsed track info
#[derive(Debug)]
struct Track {
    mode: TrackMode,
    offset: u64,
    length: u64, // in bytes
}

impl Container for NrgContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let tracks = parse_nrg(&*reader)?;

        // Return all tracks as children (audio and data)
        let mut children = Vec::new();
        for (idx, track) in tracks.iter().enumerate() {
            children.push(Child {
                index: idx as u32,
                offset: track.offset,
                reader: Arc::new(SliceReader::new(
                    Arc::clone(&reader),
                    track.offset,
                    track.length,
                )),
            });
        }

        Ok(children)
    }
}

fn read_u32_be(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_be_bytes(buf))
}

fn read_u64_be(reader: &dyn Reader, offset: u64) -> io::Result<u64> {
    let mut buf = [0u8; 8];
    if reader.read_at(offset, &mut buf)? != 8 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u64::from_be_bytes(buf))
}

fn read_bytes(reader: &dyn Reader, offset: u64, buf: &mut [u8]) -> io::Result<()> {
    if reader.read_at(offset, buf)? != buf.len() {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(())
}

/// Parse NRG image and return list of tracks
fn parse_nrg(reader: &dyn Reader) -> io::Result<Vec<Track>> {
    let file_size = reader.size().ok_or_else(|| {
        io::Error::new(io::ErrorKind::Other, "cannot determine file size")
    })?;

    if file_size < 12 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "file too small"));
    }

    // Check for NER5 (new format) at -12
    let mut sig = [0u8; 4];
    read_bytes(reader, file_size - 12, &mut sig)?;

    let (chunk_offset, is_new_format) = if &sig == b"NER5" {
        let offset = read_u64_be(reader, file_size - 8)?;
        (offset, true)
    } else {
        // Check for NERO (old format) at -8
        read_bytes(reader, file_size - 8, &mut sig)?;
        if &sig != b"NERO" {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "not an NRG file"));
        }
        let offset = read_u32_be(reader, file_size - 4)? as u64;
        (offset, false)
    };

    // Parse chunk stream
    parse_chunks(reader, chunk_offset, file_size, is_new_format)
}

/// Parse NRG chunk stream
fn parse_chunks(
    reader: &dyn Reader,
    start_offset: u64,
    file_size: u64,
    is_new_format: bool,
) -> io::Result<Vec<Track>> {
    let mut pos = start_offset;
    let mut tracks = Vec::new();

    // Track data starts at offset 0 in the file
    let data_end = start_offset; // Chunk stream starts where data ends

    loop {
        if pos + 8 > file_size {
            break;
        }

        // Read chunk header: 4-byte ID + 4-byte length
        let mut chunk_id = [0u8; 4];
        read_bytes(reader, pos, &mut chunk_id)?;
        let chunk_len = read_u32_be(reader, pos + 4)? as u64;
        pos += 8;

        match &chunk_id {
            b"END!" => break,
            b"DAOX" | b"DAOI" => {
                let new_tracks = parse_dao_chunk(reader, pos, chunk_len, is_new_format, &chunk_id)?;
                tracks.extend(new_tracks);
            }
            b"ETN2" | b"ETNF" => {
                let new_tracks = parse_etn_chunk(reader, pos, chunk_len, &chunk_id)?;
                tracks.extend(new_tracks);
            }
            _ => {
                // Skip unknown chunks (CUEX, CUES, CDTX, MTYP, SINF, etc.)
            }
        }

        pos += chunk_len;
    }

    Ok(tracks)
}

/// Parse DAO chunk (DAOX/DAOI)
fn parse_dao_chunk(
    reader: &dyn Reader,
    offset: u64,
    length: u64,
    is_new_format: bool,
    chunk_id: &[u8; 4],
) -> io::Result<Vec<Track>> {
    // DAO header is 22 bytes, then track entries follow
    // Each track entry:
    // - 12 bytes ISRC
    // - 2 bytes sector size code
    // - 1 byte mode code
    // - 1 byte unknown
    // - 2 bytes unknown
    // For DAOX: 3 x 8-byte offsets (pregap, start, end)
    // For DAOI: 3 x 4-byte offsets

    let header_size = 22u64;
    let entry_base = 18u64; // Common part before offsets
    let entry_size = if chunk_id == b"DAOX" {
        entry_base + 24 // 3 x 8 bytes
    } else {
        entry_base + 12 // 3 x 4 bytes
    };

    if length < header_size {
        return Ok(Vec::new());
    }

    let entries_len = length - header_size;
    let num_entries = entries_len / entry_size;

    let mut tracks = Vec::new();
    let mut entry_pos = offset + header_size;

    for _ in 0..num_entries {
        // Skip ISRC (12 bytes)
        // Read sector size code at +12
        let mut sector_code = [0u8; 2];
        read_bytes(reader, entry_pos + 12, &mut sector_code)?;
        let sector_size = u16::from_be_bytes(sector_code) as u32;

        // Mode code at +14
        let mut mode_buf = [0u8; 1];
        read_bytes(reader, entry_pos + 14, &mut mode_buf)?;
        let mode = match TrackMode::from_code(mode_buf[0]) {
            Some(m) => m,
            None => {
                entry_pos += entry_size;
                continue;
            }
        };

        // Read offsets
        let (pregap_offset, start_offset, end_offset) = if chunk_id == b"DAOX" {
            let pregap = read_u64_be(reader, entry_pos + 18)?;
            let start = read_u64_be(reader, entry_pos + 26)?;
            let end = read_u64_be(reader, entry_pos + 34)?;
            (pregap, start, end)
        } else {
            let pregap = read_u32_be(reader, entry_pos + 18)? as u64;
            let start = read_u32_be(reader, entry_pos + 22)? as u64;
            let end = read_u32_be(reader, entry_pos + 26)? as u64;
            (pregap, start, end)
        };

        let track_length = end_offset.saturating_sub(start_offset);

        tracks.push(Track {
            mode,
            offset: start_offset,
            length: track_length,
        });

        entry_pos += entry_size;
    }

    Ok(tracks)
}

/// Parse ETN chunk (ETN2/ETNF) for TAO mode
fn parse_etn_chunk(
    reader: &dyn Reader,
    offset: u64,
    length: u64,
    chunk_id: &[u8; 4],
) -> io::Result<Vec<Track>> {
    // ETN2: 8-byte offset, 8-byte size, 4-byte mode, 4-byte sector = 24 bytes
    // ETNF: 4-byte offset, 4-byte size, 4-byte mode, 4-byte sector = 16 bytes

    let entry_size = if chunk_id == b"ETN2" { 24u64 } else { 16u64 };
    let num_entries = length / entry_size;

    let mut tracks = Vec::new();
    let mut entry_pos = offset;

    for _ in 0..num_entries {
        let (track_offset, track_size, mode_val) = if chunk_id == b"ETN2" {
            let off = read_u64_be(reader, entry_pos)?;
            let size = read_u64_be(reader, entry_pos + 8)?;
            let mode = read_u32_be(reader, entry_pos + 16)?;
            (off, size, mode)
        } else {
            let off = read_u32_be(reader, entry_pos)? as u64;
            let size = read_u32_be(reader, entry_pos + 4)? as u64;
            let mode = read_u32_be(reader, entry_pos + 8)?;
            (off, size, mode)
        };

        let mode = match TrackMode::from_code(mode_val as u8) {
            Some(m) => m,
            None => {
                entry_pos += entry_size;
                continue;
            }
        };

        tracks.push(Track {
            mode,
            offset: track_offset,
            length: track_size,
        });

        entry_pos += entry_size;
    }

    Ok(tracks)
}
