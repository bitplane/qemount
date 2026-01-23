//! DMG (Apple Disk Image) reader
//!
//! Parses UDIF DMG format with koly trailer, XML plist, and MISH blocks.
//! Supports zlib, bzip2, lzfse compression.

use crate::container::{Child, Container};
use crate::detect::Reader;
use bzip2::read::BzDecoder;
use flate2::read::ZlibDecoder;
use std::io::{self, Read};
use std::sync::Arc;

const KOLY_MAGIC: &[u8; 4] = b"koly";
const MISH_MAGIC: u32 = 0x6d697368;

// Chunk types
const UDZE: u32 = 0x00000000; // Zeros
const UDRW: u32 = 0x00000001; // Raw
const UDIG: u32 = 0x00000002; // Ignore
const UDZO: u32 = 0x80000005; // zlib
const UDBZ: u32 = 0x80000006; // bzip2
const ULFO: u32 = 0x80000007; // lzfse
const COMMENT: u32 = 0x7ffffffe;
const LAST_ENTRY: u32 = 0xffffffff;

/// DMG disk image container
pub struct DmgContainer;

/// Static instance for registry
pub static DMG: DmgContainer = DmgContainer;

impl Container for DmgContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let dmg_reader = DmgReader::new(reader)?;

        Ok(vec![Child {
            index: 0,
            offset: 0,
            reader: Arc::new(dmg_reader),
        }])
    }
}

/// A chunk in the DMG file
#[derive(Clone)]
struct DmgChunk {
    chunk_type: u32,
    sector_start: u64,
    sector_count: u64,
    compressed_offset: u64,
    compressed_length: u64,
}

/// Reader that translates virtual disk offsets through DMG chunk table
pub struct DmgReader {
    parent: Arc<dyn Reader + Send + Sync>,
    chunks: Vec<DmgChunk>,
    data_fork_offset: u64,
    virtual_size: u64,
}

impl DmgReader {
    pub fn new(parent: Arc<dyn Reader + Send + Sync>) -> io::Result<Self> {
        // Find koly trailer - search last 512 bytes
        let mut trailer = [0u8; 512];

        // We need to find file size first - read from various offsets until we hit EOF
        // Try reading at offset 0 to check the file exists
        let mut probe = [0u8; 1];
        if parent.read_at(0, &mut probe)? == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "empty file"));
        }

        // Search backwards for koly - try common locations
        // DMG files typically have koly at EOF-512
        let koly_offset = Self::find_koly(&*parent)?;

        if parent.read_at(koly_offset, &mut trailer)? != 512 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short koly trailer read",
            ));
        }

        // Verify koly magic
        if &trailer[0..4] != KOLY_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid DMG koly magic",
            ));
        }

        // Parse koly trailer (big-endian)
        let data_fork_offset = u64::from_be_bytes([
            trailer[0x18], trailer[0x19], trailer[0x1a], trailer[0x1b],
            trailer[0x1c], trailer[0x1d], trailer[0x1e], trailer[0x1f],
        ]);
        let xml_offset = u64::from_be_bytes([
            trailer[0xd8], trailer[0xd9], trailer[0xda], trailer[0xdb],
            trailer[0xdc], trailer[0xdd], trailer[0xde], trailer[0xdf],
        ]);
        let xml_length = u64::from_be_bytes([
            trailer[0xe0], trailer[0xe1], trailer[0xe2], trailer[0xe3],
            trailer[0xe4], trailer[0xe5], trailer[0xe6], trailer[0xe7],
        ]);

        // Read XML plist
        if xml_length == 0 || xml_length > 100 * 1024 * 1024 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid XML length",
            ));
        }

        let mut xml_data = vec![0u8; xml_length as usize];
        if parent.read_at(xml_offset, &mut xml_data)? != xml_length as usize {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "short XML read",
            ));
        }

        // Parse XML to extract blkx data and build chunk table
        let xml_str = String::from_utf8_lossy(&xml_data);
        let chunks = Self::parse_plist_blkx(&xml_str, data_fork_offset)?;

        // Calculate virtual size
        let virtual_size = chunks
            .iter()
            .map(|c| (c.sector_start + c.sector_count) * 512)
            .max()
            .unwrap_or(0);

        Ok(Self {
            parent,
            chunks,
            data_fork_offset,
            virtual_size,
        })
    }

    fn find_koly(parent: &dyn Reader) -> io::Result<u64> {
        // Try to find file size by binary search
        let mut low = 0u64;
        let mut high = 1u64 << 40; // 1TB max
        let mut buf = [0u8; 1];

        // Find approximate file size
        while high - low > 512 {
            let mid = low + (high - low) / 2;
            if parent.read_at(mid, &mut buf)? > 0 {
                low = mid;
            } else {
                high = mid;
            }
        }

        // Refine to exact size
        let mut size = low;
        while parent.read_at(size, &mut buf)? > 0 {
            size += 1;
        }

        if size < 512 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "file too small for DMG",
            ));
        }

        Ok(size - 512)
    }

    fn parse_plist_blkx(
        xml: &str,
        data_fork_offset: u64,
    ) -> io::Result<Vec<DmgChunk>> {
        let mut chunks = Vec::new();
        let mut pos = 0;

        // Find all blkx entries
        while let Some(key_pos) = xml[pos..].find("<key>blkx</key>") {
            pos += key_pos + 15;

            // Find the next <data> tag
            if let Some(data_start) = xml[pos..].find("<data>") {
                let data_start = pos + data_start + 6;
                if let Some(data_end) = xml[data_start..].find("</data>") {
                    let base64_data = &xml[data_start..data_start + data_end];

                    // Decode base64
                    if let Ok(mish_data) = Self::decode_base64(base64_data) {
                        // Parse MISH block
                        if let Ok(mut block_chunks) = Self::parse_mish_block(&mish_data, data_fork_offset) {
                            chunks.append(&mut block_chunks);
                        }
                    }

                    pos = data_start + data_end;
                }
            }
        }

        if chunks.is_empty() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "no valid blkx entries found",
            ));
        }

        // Sort chunks by sector_start for binary search
        chunks.sort_by_key(|c| c.sector_start);

        Ok(chunks)
    }

    fn decode_base64(input: &str) -> io::Result<Vec<u8>> {
        const BASE64_TABLE: &[u8; 64] =
            b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        let mut output = Vec::new();
        let mut accum = 0u32;
        let mut bits = 0u32;

        for byte in input.bytes() {
            let val = if byte == b'=' {
                continue;
            } else if let Some(idx) = BASE64_TABLE.iter().position(|&b| b == byte) {
                idx as u32
            } else if byte.is_ascii_whitespace() {
                continue;
            } else {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "invalid base64",
                ));
            };

            accum = (accum << 6) | val;
            bits += 6;

            if bits >= 8 {
                bits -= 8;
                output.push((accum >> bits) as u8);
                accum &= (1 << bits) - 1;
            }
        }

        Ok(output)
    }

    fn parse_mish_block(data: &[u8], data_fork_offset: u64) -> io::Result<Vec<DmgChunk>> {
        if data.len() < 204 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "MISH block too short",
            ));
        }

        // Check MISH magic (big-endian)
        let magic = u32::from_be_bytes([data[0], data[1], data[2], data[3]]);
        if magic != MISH_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid MISH magic",
            ));
        }

        // Get block's base sector offset
        let block_sector_start = u64::from_be_bytes([
            data[8], data[9], data[10], data[11],
            data[12], data[13], data[14], data[15],
        ]);

        // Chunk entries start at offset 204
        let mut chunks = Vec::new();
        let mut offset = 204;

        while offset + 40 <= data.len() {
            let chunk_type = u32::from_be_bytes([
                data[offset], data[offset + 1], data[offset + 2], data[offset + 3],
            ]);

            // Skip comment and check for last entry
            if chunk_type == COMMENT || chunk_type == UDIG {
                offset += 40;
                continue;
            }
            if chunk_type == LAST_ENTRY {
                break;
            }

            let sector_number = u64::from_be_bytes([
                data[offset + 8], data[offset + 9], data[offset + 10], data[offset + 11],
                data[offset + 12], data[offset + 13], data[offset + 14], data[offset + 15],
            ]);
            let sector_count = u64::from_be_bytes([
                data[offset + 16], data[offset + 17], data[offset + 18], data[offset + 19],
                data[offset + 20], data[offset + 21], data[offset + 22], data[offset + 23],
            ]);
            let compressed_offset = u64::from_be_bytes([
                data[offset + 24], data[offset + 25], data[offset + 26], data[offset + 27],
                data[offset + 28], data[offset + 29], data[offset + 30], data[offset + 31],
            ]);
            let compressed_length = u64::from_be_bytes([
                data[offset + 32], data[offset + 33], data[offset + 34], data[offset + 35],
                data[offset + 36], data[offset + 37], data[offset + 38], data[offset + 39],
            ]);

            // Only add chunks with actual data
            if sector_count > 0 {
                chunks.push(DmgChunk {
                    chunk_type,
                    sector_start: block_sector_start + sector_number,
                    sector_count,
                    compressed_offset: data_fork_offset + compressed_offset,
                    compressed_length,
                });
            }

            offset += 40;
        }

        Ok(chunks)
    }

    fn find_chunk(&self, sector: u64) -> Option<&DmgChunk> {
        // Binary search for chunk containing this sector
        let idx = self.chunks.partition_point(|c| c.sector_start + c.sector_count <= sector);

        if idx < self.chunks.len() {
            let chunk = &self.chunks[idx];
            if sector >= chunk.sector_start && sector < chunk.sector_start + chunk.sector_count {
                return Some(chunk);
            }
        }

        None
    }

    fn decompress_chunk(&self, chunk: &DmgChunk) -> io::Result<Vec<u8>> {
        let uncompressed_size = (chunk.sector_count * 512) as usize;

        match chunk.chunk_type {
            UDZE => {
                // Zeros - no need to read
                Ok(vec![0u8; uncompressed_size])
            }
            UDRW => {
                // Raw - read directly
                let mut data = vec![0u8; uncompressed_size];
                self.parent.read_at(chunk.compressed_offset, &mut data)?;
                Ok(data)
            }
            UDZO => {
                // zlib
                let mut compressed = vec![0u8; chunk.compressed_length as usize];
                self.parent.read_at(chunk.compressed_offset, &mut compressed)?;

                let mut decoder = ZlibDecoder::new(&compressed[..]);
                let mut decompressed = vec![0u8; uncompressed_size];
                decoder.read_exact(&mut decompressed)?;
                Ok(decompressed)
            }
            UDBZ => {
                // bzip2
                let mut compressed = vec![0u8; chunk.compressed_length as usize];
                self.parent.read_at(chunk.compressed_offset, &mut compressed)?;

                let mut decoder = BzDecoder::new(&compressed[..]);
                let mut decompressed = vec![0u8; uncompressed_size];
                decoder.read_exact(&mut decompressed)?;
                Ok(decompressed)
            }
            ULFO => {
                // lzfse
                let mut compressed = vec![0u8; chunk.compressed_length as usize];
                self.parent.read_at(chunk.compressed_offset, &mut compressed)?;

                let mut decompressed = vec![0u8; uncompressed_size];
                let decoded_len = lzfse::decode_buffer(&compressed, &mut decompressed)
                    .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "lzfse decode error"))?;

                if decoded_len < uncompressed_size {
                    return Err(io::Error::new(
                        io::ErrorKind::InvalidData,
                        "lzfse: short decompression",
                    ));
                }
                Ok(decompressed)
            }
            _ => {
                // Unknown compression - return zeros as fallback
                Ok(vec![0u8; uncompressed_size])
            }
        }
    }
}

impl Reader for DmgReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        let sector = offset / 512;
        let in_sector = (offset % 512) as usize;

        // Find chunk containing this sector
        let chunk = match self.find_chunk(sector) {
            Some(c) => c.clone(),
            None => {
                // No chunk - return zeros
                let remaining = (self.virtual_size - offset) as usize;
                let to_read = buf.len().min(remaining).min(512 - in_sector);
                buf[..to_read].fill(0);
                return Ok(to_read);
            }
        };

        // Calculate position within chunk
        let chunk_sector_offset = sector - chunk.sector_start;
        let chunk_byte_offset = chunk_sector_offset * 512 + in_sector as u64;
        let chunk_size = chunk.sector_count * 512;

        // How much can we read from this chunk?
        let remaining_in_chunk = (chunk_size - chunk_byte_offset) as usize;
        let remaining_in_disk = (self.virtual_size - offset) as usize;
        let to_read = buf.len().min(remaining_in_chunk).min(remaining_in_disk);

        // Decompress chunk and extract data
        let decompressed = self.decompress_chunk(&chunk)?;
        buf[..to_read].copy_from_slice(&decompressed[chunk_byte_offset as usize..][..to_read]);

        Ok(to_read)
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: DmgReader only holds Arc and Vec, safe to send/share
unsafe impl Send for DmgReader {}
unsafe impl Sync for DmgReader {}
