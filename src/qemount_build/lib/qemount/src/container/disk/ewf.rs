//! EWF (Expert Witness Format) disk image reader
//!
//! Parses EWF v1 (E01) forensic disk images. Chunks are zlib compressed
//! with an offset table for random access, similar to cloop.

use crate::container::{Child, Container};
use crate::detect::Reader;
use flate2::read::ZlibDecoder;
use std::io::{self, Read};
use std::sync::Arc;

const FILE_HEADER_SIZE: u64 = 13;
const SECTION_DESCRIPTOR_SIZE: usize = 76;
const TABLE_HEADER_SIZE: usize = 24; // chunk_count(4) + padding(16) + checksum(4)
const COMPRESSED_FLAG: u32 = 0x8000_0000;
const MAX_CHUNK_SIZE: u32 = 64 * 1024 * 1024;

/// EWF disk image container
pub struct EwfContainer;

/// Static instance for registry
pub static EWF: EwfContainer = EwfContainer;

impl Container for EwfContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let ewf_reader = EwfReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(ewf_reader),
        }])
    }
}

/// Section location parsed from walking the section chain
struct SectionInfo {
    /// Offset of the sectors section (chunk offsets are relative to this)
    sectors_offset: u64,
    /// Offset of the next section after sectors (bounds the last chunk)
    sectors_end: u64,
    /// Chunk count from the volume/data section
    chunk_count: u32,
    /// Bytes per chunk (sectors_per_chunk * bytes_per_sector)
    chunk_size: u32,
    /// Total virtual disk size in bytes
    virtual_size: u64,
    /// Chunk offset entries from the table section
    chunk_offsets: Vec<u32>,
}

/// Reader that translates virtual disk offsets through EWF chunk table
pub struct EwfReader {
    parent: Arc<dyn Reader + Send + Sync>,
    sectors_offset: u64,
    sectors_end: u64,
    chunk_offsets: Vec<u32>,
    chunk_size: u64,
    virtual_size: u64,
}

fn read_le_u32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_le_bytes(buf))
}

fn read_le_u64(reader: &dyn Reader, offset: u64) -> io::Result<u64> {
    let mut buf = [0u8; 8];
    if reader.read_at(offset, &mut buf)? != 8 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u64::from_le_bytes(buf))
}

fn parse_sections(reader: &dyn Reader) -> io::Result<SectionInfo> {
    let mut pos = FILE_HEADER_SIZE;
    let mut sectors_offset = 0u64;
    let mut sectors_end = 0u64;
    let mut chunk_count = 0u32;
    let mut chunk_size = 0u32;
    let mut virtual_size = 0u64;
    let mut chunk_offsets = Vec::new();

    loop {
        // Read section type (first 16 bytes of descriptor)
        let mut type_buf = [0u8; 16];
        if reader.read_at(pos, &mut type_buf)? != 16 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short section descriptor read",
            ));
        }
        let section_type = std::str::from_utf8(&type_buf)
            .unwrap_or("")
            .trim_end_matches('\0');

        let next_offset = read_le_u64(reader, pos + 16)?;

        match section_type {
            "volume" | "data" => {
                // Volume/data section: parse disk geometry after descriptor
                let vol_start = pos + SECTION_DESCRIPTOR_SIZE as u64;
                // Fields: reserved(4), chunk_count(4), sectors_per_chunk(4),
                //         bytes_per_sector(4), sector_count(8)
                chunk_count = read_le_u32(reader, vol_start + 4)?;
                let sectors_per_chunk = read_le_u32(reader, vol_start + 8)?;
                let bytes_per_sector = read_le_u32(reader, vol_start + 12)?;
                let sector_count = read_le_u64(reader, vol_start + 16)?;

                chunk_size = sectors_per_chunk
                    .checked_mul(bytes_per_sector)
                    .filter(|&s| s > 0 && s <= MAX_CHUNK_SIZE)
                    .ok_or_else(|| {
                        io::Error::new(io::ErrorKind::InvalidData, "invalid chunk size")
                    })?;
                virtual_size = sector_count * bytes_per_sector as u64;
            }
            "sectors" => {
                sectors_offset = pos;
                sectors_end = next_offset;
            }
            "table" if chunk_offsets.is_empty() => {
                // First table section: read chunk offset entries
                let tbl_start = pos + SECTION_DESCRIPTOR_SIZE as u64;
                let tbl_count = read_le_u32(reader, tbl_start)?;

                let entries_start = tbl_start + TABLE_HEADER_SIZE as u64;
                let entries_bytes = tbl_count as usize * 4;
                let mut entries_data = vec![0u8; entries_bytes];
                if reader.read_at(entries_start, &mut entries_data)? != entries_bytes {
                    return Err(io::Error::new(
                        io::ErrorKind::UnexpectedEof,
                        "short table read",
                    ));
                }

                chunk_offsets = entries_data
                    .chunks_exact(4)
                    .map(|c| u32::from_le_bytes([c[0], c[1], c[2], c[3]]))
                    .collect();
            }
            "done" => break,
            _ => {}
        }

        if next_offset == pos || next_offset == 0 {
            break;
        }
        pos = next_offset;
    }

    if sectors_offset == 0 || chunk_offsets.is_empty() || chunk_size == 0 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "missing required EWF sections",
        ));
    }

    Ok(SectionInfo {
        sectors_offset,
        sectors_end,
        chunk_count,
        chunk_size,
        virtual_size,
        chunk_offsets,
    })
}

impl EwfReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Verify magic
        let mut magic = [0u8; 8];
        if parent.read_at(0, &mut magic)? != 8 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short EWF header read",
            ));
        }
        if &magic != b"EVF\x09\x0d\x0a\xff\x00" {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "not an EWF v1 file",
            ));
        }

        let info = parse_sections(parent.as_ref())?;

        if info.chunk_offsets.len() != info.chunk_count as usize {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "table/volume chunk count mismatch",
            ));
        }

        Ok(Self {
            parent,
            sectors_offset: info.sectors_offset,
            sectors_end: info.sectors_end,
            chunk_offsets: info.chunk_offsets,
            chunk_size: info.chunk_size as u64,
            virtual_size: info.virtual_size,
        })
    }

    fn read_chunk(&self, chunk_idx: usize) -> io::Result<Vec<u8>> {
        if chunk_idx >= self.chunk_offsets.len() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "chunk index out of range",
            ));
        }

        let entry = self.chunk_offsets[chunk_idx];
        let compressed = entry & COMPRESSED_FLAG != 0;
        let rel_offset = (entry & !COMPRESSED_FLAG) as u64;
        let abs_offset = self.sectors_offset + rel_offset;

        // Determine compressed size from next chunk or section end
        let end = if chunk_idx + 1 < self.chunk_offsets.len() {
            let next_entry = self.chunk_offsets[chunk_idx + 1];
            let next_rel = (next_entry & !COMPRESSED_FLAG) as u64;
            self.sectors_offset + next_rel
        } else {
            self.sectors_end
        };
        let data_size = (end - abs_offset) as usize;

        let mut raw = vec![0u8; data_size];
        self.parent.read_at(abs_offset, &mut raw)?;

        if compressed {
            let mut decoder = ZlibDecoder::new(&raw[..]);
            let mut decompressed = vec![0u8; self.chunk_size as usize];
            decoder.read_exact(&mut decompressed)?;
            Ok(decompressed)
        } else {
            Ok(raw)
        }
    }
}

impl Reader for EwfReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        let chunk_idx = (offset / self.chunk_size) as usize;
        let in_chunk = (offset % self.chunk_size) as usize;

        let remaining_in_chunk = self.chunk_size as usize - in_chunk;
        let remaining_in_disk = (self.virtual_size - offset) as usize;
        let to_read = buf.len().min(remaining_in_chunk).min(remaining_in_disk);

        let decompressed = self.read_chunk(chunk_idx)?;
        buf[..to_read].copy_from_slice(&decompressed[in_chunk..][..to_read]);

        Ok(to_read)
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: EwfReader only holds Arc and Vec, safe to send/share
unsafe impl Send for EwfReader {}
unsafe impl Sync for EwfReader {}
