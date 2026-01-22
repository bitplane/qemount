//! AIX LVM partition table reader
//!
//! Parses AIX Logical Volume Manager headers and returns children for each
//! contiguous logical volume.

use crate::container::slice::SliceReader;
use crate::container::{Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

/// Sector size
const SECTOR: u64 = 512;

/// LVM record at sector 7
const LVM_SECTOR: u64 = 7;

/// Maximum logical volumes
const MAX_LVS: usize = 256;

/// AIX LVM container
pub struct AixContainer;

/// Static instance for registry
pub static AIX: AixContainer = AixContainer;

impl Container for AixContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        // Read LVM record at sector 7
        let lvm_offset = LVM_SECTOR * SECTOR;

        // Verify magic "_LVM"
        let mut magic = [0u8; 4];
        if reader.read_at(lvm_offset, &mut magic)? != 4 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "short read"));
        }
        if &magic != b"_LVM" {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "AIX LVM magic not found",
            ));
        }

        // Read LVM record fields
        let pp_size_log2 = read_be16(&*reader, lvm_offset + 0x2E)?;
        let vgda_len = read_be32(&*reader, lvm_offset + 0x18)?;
        let vgda_sector = read_be32(&*reader, lvm_offset + 0x1C)? as u64;

        if vgda_sector == 0 || pp_size_log2 > 30 {
            return Ok(vec![]);
        }

        let pp_bytes = 1u64 << pp_size_log2;
        let pp_blocks = pp_bytes / SECTOR;

        // Read VGDA header
        let vgda_offset = vgda_sector * SECTOR;
        let numlvs = read_be16(&*reader, vgda_offset + 0x18)? as usize;

        if numlvs == 0 || numlvs > MAX_LVS {
            return Ok(vec![]);
        }

        // Read LV descriptors to get num_lps per LV (at VGDA + 1 sector)
        let lvd_offset = (vgda_sector + 1) * SECTOR;
        let mut lv_num_lps = vec![0u16; MAX_LVS];
        for i in 0..numlvs.min(MAX_LVS) {
            // Each LVD is 32 bytes, num_lps at offset 0x0E
            let entry_offset = lvd_offset + (i * 32) as u64;
            lv_num_lps[i] = read_be16(&*reader, entry_offset + 0x0E)?;
        }

        // Read PVD (at VGDA + 17 sectors)
        let pvd_offset = (vgda_sector + 17) * SECTOR;
        let pp_count = read_be16(&*reader, pvd_offset + 0x10)? as usize;
        let psn_part1 = read_be32(&*reader, pvd_offset + 0x14)? as u64;

        // Track LV state: (first_pp_index, lps_found, is_contiguous)
        let mut lv_state: Vec<(Option<usize>, u16, bool)> = vec![(None, 0, true); MAX_LVS];

        // Scan PPEs (Physical Partition Entries) at PVD + 0x20
        // Each PPE is 32 bytes
        let ppe_base = pvd_offset + 0x20;
        let mut cur_lv_ix: Option<usize> = None;
        let mut next_lp_ix: u16 = 1;

        for i in 0..pp_count.min(1016) {
            let ppe_offset = ppe_base + (i * 32) as u64;
            let lv_ix = read_be16(&*reader, ppe_offset)?;
            let lp_ix = read_be16(&*reader, ppe_offset + 6)?;

            if lp_ix == 0 {
                // Free PP
                cur_lv_ix = None;
                next_lp_ix = 1;
                continue;
            }

            let lv_idx = (lv_ix as usize).saturating_sub(1);
            if lv_idx >= MAX_LVS {
                cur_lv_ix = None;
                continue;
            }

            lv_state[lv_idx].1 += 1; // Increment LPs found

            if lp_ix == 1 {
                // Start of LV
                lv_state[lv_idx].0 = Some(i);
                cur_lv_ix = Some(lv_idx);
                next_lp_ix = 2;
            } else if Some(lv_idx) == cur_lv_ix && lp_ix == next_lp_ix {
                // Contiguous continuation
                next_lp_ix += 1;
            } else {
                // Non-contiguous
                lv_state[lv_idx].2 = false;
                cur_lv_ix = None;
                next_lp_ix = 1;
            }
        }

        // Build children for contiguous LVs
        let mut children = Vec::new();
        for (lv_idx, (first_pp, lps_found, is_contiguous)) in lv_state.iter().enumerate() {
            let first_pp = match first_pp {
                Some(pp) => *pp,
                None => continue,
            };

            if !is_contiguous || *lps_found == 0 {
                continue;
            }

            let expected_lps = lv_num_lps[lv_idx];
            if *lps_found != expected_lps {
                continue;
            }

            let start_sector = psn_part1 + (first_pp as u64 * pp_blocks);
            let start = start_sector * SECTOR;
            let length = *lps_found as u64 * pp_bytes;

            children.push(Child {
                index: lv_idx as u32,
                offset: start,
                reader: Arc::new(SliceReader::new(Arc::clone(&reader), start, length)),
            });
        }

        Ok(children)
    }
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
