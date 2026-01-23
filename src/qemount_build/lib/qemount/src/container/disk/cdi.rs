//! CDI (DiscJuggler) disc image reader
//!
//! Parses CDI format and exposes data tracks for filesystem detection.
//! Based on cdirip by DeXT/Lawrence Williams.

use crate::container::{slice::SliceReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

const CDI_V2: u32 = 0x80000004;
const CDI_V3: u32 = 0x80000005;
const CDI_V35: u32 = 0x80000006;

const TRACK_MARKER: [u8; 10] = [0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF];

/// CDI disc image container
pub struct CdiContainer;

/// Static instance for registry
pub static CDI: CdiContainer = CdiContainer;

/// Track mode
#[derive(Debug, Clone, Copy, PartialEq)]
enum TrackMode {
    Audio = 0,
    Mode1 = 1,
    Mode2 = 2,
}

/// Parsed track info
#[derive(Debug)]
struct Track {
    mode: TrackMode,
    sector_size: u32,
    pregap_length: u32,
    length: u32,
    start_lba: u32,
    total_length: u32,
    data_offset: u64, // File position where track data starts
}

impl Container for CdiContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let tracks = parse_cdi(&*reader)?;

        // Return all tracks as children (audio and data)
        let mut children = Vec::new();
        for (idx, track) in tracks.iter().enumerate() {
            // Calculate track data size
            let data_size = track.length as u64 * track.sector_size as u64;

            children.push(Child {
                index: idx as u32,
                offset: track.data_offset,
                reader: Arc::new(SliceReader::new(
                    Arc::clone(&reader),
                    track.data_offset,
                    data_size,
                )),
            });
        }

        Ok(children)
    }
}

fn read_u16_le(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut buf = [0u8; 2];
    if reader.read_at(offset, &mut buf)? != 2 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u16::from_le_bytes(buf))
}

fn read_u32_le(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_le_bytes(buf))
}

fn read_bytes(reader: &dyn Reader, offset: u64, buf: &mut [u8]) -> io::Result<()> {
    if reader.read_at(offset, buf)? != buf.len() {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(())
}

/// Parse CDI image and return list of tracks
fn parse_cdi(reader: &dyn Reader) -> io::Result<Vec<Track>> {
    let file_size = reader.size().ok_or_else(|| {
        io::Error::new(io::ErrorKind::Other, "cannot determine file size")
    })?;

    if file_size < 8 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "file too small"));
    }

    // Read footer
    let version = read_u32_le(reader, file_size - 8)?;
    let header_offset = read_u32_le(reader, file_size - 4)?;

    if header_offset == 0 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "bad header offset"));
    }

    // Determine header position based on version
    let header_pos = match version {
        CDI_V35 => file_size - header_offset as u64,
        CDI_V2 | CDI_V3 => header_offset as u64,
        _ => return Err(io::Error::new(io::ErrorKind::InvalidData, "unknown CDI version")),
    };

    // Read session count
    let sessions = read_u16_le(reader, header_pos)?;
    let mut pos = header_pos + 2;
    let mut data_pos = 0u64; // Track data starts at beginning of file

    let mut tracks = Vec::new();
    let mut global_track = 0u32;

    for _session in 0..sessions {
        // Read track count for this session
        let track_count = read_u16_le(reader, pos)?;
        pos += 2;

        for _track_num in 0..track_count {
            let (track, new_pos) = parse_track(reader, pos, version, data_pos, global_track)?;

            // Advance data position past this track's data
            data_pos += (track.pregap_length as u64 + track.length as u64) * track.sector_size as u64;

            tracks.push(track);
            pos = new_pos;
            global_track += 1;
        }

        // Skip session footer
        pos += 4 + 8;
        if version != CDI_V2 {
            pos += 1;
        }
    }

    Ok(tracks)
}

/// Parse a single track header, returning the track and the new file position
fn parse_track(
    reader: &dyn Reader,
    mut pos: u64,
    version: u32,
    data_pos: u64,
    _global_track: u32,
) -> io::Result<(Track, u64)> {
    // Check for extra data (DJ 3.00.780+)
    let temp = read_u32_le(reader, pos)?;
    pos += 4;
    if temp != 0 {
        pos += 8;
    }

    // Verify track start markers
    let mut marker = [0u8; 10];
    read_bytes(reader, pos, &mut marker)?;
    if marker != TRACK_MARKER {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "missing track start marker",
        ));
    }
    pos += 10;

    read_bytes(reader, pos, &mut marker)?;
    if marker != TRACK_MARKER {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "missing second track start marker",
        ));
    }
    pos += 10;

    // Skip 4 bytes
    pos += 4;

    // Read filename length and skip filename
    let mut filename_len_buf = [0u8; 1];
    read_bytes(reader, pos, &mut filename_len_buf)?;
    let filename_len = filename_len_buf[0] as u64;
    pos += 1 + filename_len;

    // Skip 11 + 4 + 4 bytes
    pos += 11 + 4 + 4;

    // Check for DJ4 marker
    let temp = read_u32_le(reader, pos)?;
    pos += 4;
    if temp == 0x80000000 {
        pos += 8;
    }

    // Skip 2 bytes
    pos += 2;

    // Read track info
    let pregap_length = read_u32_le(reader, pos)?;
    pos += 4;

    let length = read_u32_le(reader, pos)?;
    pos += 4;

    // Skip 6 bytes
    pos += 6;

    let mode_val = read_u32_le(reader, pos)?;
    pos += 4;
    let mode = match mode_val {
        0 => TrackMode::Audio,
        1 => TrackMode::Mode1,
        2 => TrackMode::Mode2,
        _ => {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "unsupported track mode",
            ))
        }
    };

    // Skip 12 bytes
    pos += 12;

    let start_lba = read_u32_le(reader, pos)?;
    pos += 4;

    let total_length = read_u32_le(reader, pos)?;
    pos += 4;

    // Skip 16 bytes
    pos += 16;

    let sector_size_val = read_u32_le(reader, pos)?;
    pos += 4;
    let sector_size = match sector_size_val {
        0 => 2048,
        1 => 2336,
        2 => 2352,
        _ => {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "unsupported sector size",
            ))
        }
    };

    // Skip 29 bytes
    pos += 29;

    // Version-specific extra data
    if version != CDI_V2 {
        pos += 5;
        let temp = read_u32_le(reader, pos)?;
        pos += 4;
        if temp == 0xffffffff {
            pos += 78;
        }
    }

    // Calculate where track data starts (after pregap)
    let track_data_offset = data_pos + (pregap_length as u64 * sector_size as u64);

    Ok((
        Track {
            mode,
            sector_size,
            pregap_length,
            length,
            start_lba,
            total_length,
            data_offset: track_data_offset,
        },
        pos,
    ))
}
