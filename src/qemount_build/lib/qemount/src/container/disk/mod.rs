//! Disk image container readers
//!
//! Disk image formats (Parallels, QCOW2, VHD, etc.) contain virtual disks
//! that can be recursively detected for partition tables and filesystems.

pub mod bochs;
pub mod cdi;
pub mod cloop;
pub mod dmg;
pub mod parallels;
pub mod qcow;
pub mod qcow2;
pub mod qed;
pub mod vdi;
pub mod vhd;
pub mod vhdx;
pub mod vmdk;
