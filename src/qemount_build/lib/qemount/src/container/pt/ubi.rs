//! UBI (Unsorted Block Images) container reader
//!
//! Parses UBI volume management layer for raw NAND flash.
//! Scans physical erase blocks (PEBs) to find volumes and reconstructs
//! logical erase blocks (LEBs) for each volume.

use crate::container::{Child, Container};
use crate::detect::Reader;
use std::collections::BTreeMap;
use std::io;
use std::sync::Arc;

// Magic numbers (big-endian)
const EC_HDR_MAGIC: u32 = 0x55424923; // "UBI#"
const VID_HDR_MAGIC: u32 = 0x55424921; // "UBI!"

// Internal volume IDs
const UBI_INTERNAL_VOL_START: u32 = 0x7FFFEFFF;
const UBI_LAYOUT_VOLUME_ID: u32 = UBI_INTERNAL_VOL_START;

// Limits
const MAX_PEBS: usize = 65536;
const MAX_VOLUMES: usize = 128;
const VTBL_RECORD_SIZE: usize = 172;

// Common PEB sizes to probe (in bytes)
const PEB_SIZES: &[u64] = &[
    128 * 1024,  // 128 KiB - common for SLC NAND
    256 * 1024,  // 256 KiB
    512 * 1024,  // 512 KiB
    64 * 1024,   // 64 KiB - older/smaller flash
    1024 * 1024, // 1 MiB - large page NAND
];

/// UBI partition table container
pub struct UbiContainer;

/// Static instance for registry
pub static UBI: UbiContainer = UbiContainer;

/// Volume info from volume table
#[derive(Clone)]
struct VolumeInfo {
    _name: String,
    _vol_type: u8,
    _reserved_pebs: u32,
}

/// Mapping of LEB number to (PEB data offset, data size)
type LebMap = BTreeMap<u32, (u64, u64)>;

impl Container for UbiContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Detect PEB size by scanning for EC headers
        let peb_size = detect_peb_size(&*reader)?;

        // Scan all PEBs and build volume maps
        let (vol_maps, _vid_hdr_offset, data_offset) = scan_pebs(&*reader, peb_size)?;

        // Calculate LEB size (data area per PEB)
        let leb_size = peb_size - data_offset;

        // Read volume table from layout volume (for future use)
        let _vtbl = read_volume_table(&*reader, &vol_maps, leb_size)?;

        // Create children for each user volume
        let mut children = Vec::new();

        for (vol_id, leb_map) in &vol_maps {
            // Skip internal volumes
            if *vol_id >= UBI_INTERNAL_VOL_START {
                continue;
            }

            // Create reader for this volume
            let vol_reader = UbiVolumeReader::new(
                Arc::clone(&reader),
                leb_map.clone(),
                leb_size,
            );

            children.push(Child {
                index: *vol_id,
                offset: 0, // UBI volumes don't have a simple offset
                reader: Arc::new(vol_reader),
            });
        }

        // Sort by volume ID
        children.sort_by_key(|c| c.index);

        Ok(children)
    }
}

/// Detect PEB size by finding consecutive EC headers
fn detect_peb_size(reader: &dyn Reader) -> io::Result<u64> {
    // First, verify we have a valid EC header at offset 0
    if read_be32(reader, 0)? != EC_HDR_MAGIC {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "no UBI EC header at offset 0",
        ));
    }

    // Try each candidate PEB size
    for &peb_size in PEB_SIZES {
        // Check if there's another EC header at this offset
        if let Ok(magic) = read_be32(reader, peb_size) {
            if magic == EC_HDR_MAGIC {
                // Verify a third one to be sure
                if let Ok(magic2) = read_be32(reader, peb_size * 2) {
                    if magic2 == EC_HDR_MAGIC {
                        return Ok(peb_size);
                    }
                }
                // Two is probably enough
                return Ok(peb_size);
            }
        }
    }

    // Fallback: try to detect from vid_hdr_offset alignment
    // Many implementations use 2048 sub-page with 128K PEB
    Ok(128 * 1024)
}

/// Scan all PEBs and build volume -> LEB maps
fn scan_pebs(
    reader: &dyn Reader,
    peb_size: u64,
) -> io::Result<(BTreeMap<u32, LebMap>, u64, u64)> {
    let mut vol_maps: BTreeMap<u32, LebMap> = BTreeMap::new();
    let mut vid_hdr_offset = 0u64;
    let mut data_offset = 0u64;

    for peb_num in 0..MAX_PEBS {
        let peb_start = peb_num as u64 * peb_size;

        // Try to read EC header
        let magic = match read_be32(reader, peb_start) {
            Ok(m) => m,
            Err(_) => break, // EOF
        };

        if magic != EC_HDR_MAGIC {
            continue; // Empty or bad PEB
        }

        // Read EC header fields
        let peb_vid_offset = read_be32(reader, peb_start + 0x10)? as u64;
        let peb_data_offset = read_be32(reader, peb_start + 0x14)? as u64;

        if vid_hdr_offset == 0 {
            vid_hdr_offset = peb_vid_offset;
            data_offset = peb_data_offset;
        }

        // Read VID header
        let vid_start = peb_start + peb_vid_offset;
        let vid_magic = match read_be32(reader, vid_start) {
            Ok(m) => m,
            Err(_) => continue, // No VID header (free PEB)
        };

        if vid_magic != VID_HDR_MAGIC {
            continue; // Free or erased PEB
        }

        // Parse VID header
        let vol_id = read_be32(reader, vid_start + 0x08)?;
        let lnum = read_be32(reader, vid_start + 0x0C)?;
        let data_size = read_be32(reader, vid_start + 0x14)? as u64;

        // Add to volume map (later PEBs overwrite earlier - usually newer)
        let leb_map = vol_maps.entry(vol_id).or_insert_with(BTreeMap::new);
        let abs_data_offset = peb_start + peb_data_offset;
        leb_map.insert(lnum, (abs_data_offset, data_size));
    }

    if vol_maps.is_empty() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "no UBI volumes found",
        ));
    }

    Ok((vol_maps, vid_hdr_offset, data_offset))
}

/// Read volume table from layout volume
fn read_volume_table(
    reader: &dyn Reader,
    vol_maps: &BTreeMap<u32, LebMap>,
    leb_size: u64,
) -> io::Result<Vec<Option<VolumeInfo>>> {
    let mut vtbl: Vec<Option<VolumeInfo>> = vec![None; MAX_VOLUMES];

    // Find layout volume
    let layout_map = match vol_maps.get(&UBI_LAYOUT_VOLUME_ID) {
        Some(m) => m,
        None => return Ok(vtbl), // No volume table, return empty
    };

    // Read LEB 0 of layout volume
    let (data_offset, _) = match layout_map.get(&0) {
        Some(&entry) => entry,
        None => return Ok(vtbl),
    };

    // Parse volume table records
    let records_per_leb = leb_size as usize / VTBL_RECORD_SIZE;
    let num_records = records_per_leb.min(MAX_VOLUMES);

    for i in 0..num_records {
        let rec_offset = data_offset + (i * VTBL_RECORD_SIZE) as u64;

        // Read record
        let reserved_pebs = match read_be32(reader, rec_offset) {
            Ok(v) => v,
            Err(_) => continue,
        };

        // Empty record check
        if reserved_pebs == 0 {
            continue;
        }

        let vol_type = match read_byte(reader, rec_offset + 12) {
            Ok(v) => v,
            Err(_) => continue,
        };

        let name_len = match read_be16(reader, rec_offset + 14) {
            Ok(v) => v as usize,
            Err(_) => continue,
        };

        // Read volume name
        let name = if name_len > 0 && name_len <= 127 {
            let mut name_buf = vec![0u8; name_len];
            if reader.read_at(rec_offset + 16, &mut name_buf)? == name_len {
                String::from_utf8_lossy(&name_buf).to_string()
            } else {
                String::new()
            }
        } else {
            String::new()
        };

        vtbl[i] = Some(VolumeInfo {
            _name: name,
            _vol_type: vol_type,
            _reserved_pebs: reserved_pebs,
        });
    }

    Ok(vtbl)
}

/// Reader for a UBI volume that reconstructs LEBs
pub struct UbiVolumeReader {
    parent: Arc<dyn Reader + Send + Sync>,
    leb_map: LebMap,
    leb_size: u64,
    virtual_size: u64,
}

impl UbiVolumeReader {
    pub fn new(
        parent: Arc<dyn Reader + Send + Sync>,
        leb_map: LebMap,
        leb_size: u64,
    ) -> Self {
        // Calculate virtual size from highest LEB
        let virtual_size = leb_map
            .keys()
            .max()
            .map(|&max_leb| (max_leb as u64 + 1) * leb_size)
            .unwrap_or(0);

        Self {
            parent,
            leb_map,
            leb_size,
            virtual_size,
        }
    }
}

impl Reader for UbiVolumeReader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        if offset >= self.virtual_size {
            return Ok(0);
        }

        // Calculate LEB and offset within LEB
        let leb_num = (offset / self.leb_size) as u32;
        let in_leb = offset % self.leb_size;

        // How much can we read from this LEB?
        let remaining_in_leb = self.leb_size - in_leb;
        let remaining_in_vol = self.virtual_size - offset;
        let to_read = buf
            .len()
            .min(remaining_in_leb as usize)
            .min(remaining_in_vol as usize);

        // Find LEB in map
        match self.leb_map.get(&leb_num) {
            Some(&(data_offset, _data_size)) => {
                // Read from physical location
                self.parent.read_at(data_offset + in_leb, &mut buf[..to_read])
            }
            None => {
                // Unmapped LEB - return zeros (sparse)
                buf[..to_read].fill(0);
                Ok(to_read)
            }
        }
    }

    fn size(&self) -> Option<u64> {
        Some(self.virtual_size)
    }
}

// SAFETY: UbiVolumeReader only holds Arc and BTreeMap, safe to send/share
unsafe impl Send for UbiVolumeReader {}
unsafe impl Sync for UbiVolumeReader {}

// Helper functions
fn read_byte(reader: &dyn Reader, offset: u64) -> io::Result<u8> {
    let mut buf = [0u8; 1];
    if reader.read_at(offset, &mut buf)? != 1 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(buf[0])
}

fn read_be16(reader: &dyn Reader, offset: u64) -> io::Result<u16> {
    let mut buf = [0u8; 2];
    if reader.read_at(offset, &mut buf)? != 2 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u16::from_be_bytes(buf))
}

fn read_be32(reader: &dyn Reader, offset: u64) -> io::Result<u32> {
    let mut buf = [0u8; 4];
    if reader.read_at(offset, &mut buf)? != 4 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u32::from_be_bytes(buf))
}

fn read_be64(reader: &dyn Reader, offset: u64) -> io::Result<u64> {
    let mut buf = [0u8; 8];
    if reader.read_at(offset, &mut buf)? != 8 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
    }
    Ok(u64::from_be_bytes(buf))
}
