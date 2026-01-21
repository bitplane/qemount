---
title: VMDK
created: 1999
related:
  - format/disk/vdi
  - format/disk/vhd
  - format/disk/qcow2
detect:
  any:
    - offset: 0
      type: le32
      value: 0x564d444b
      name: "VMDK sparse"
    - offset: 0
      type: string
      length: 4
      value: "KDMV"
      name: "VMDK sparse (alt)"
    - offset: 0
      type: string
      length: 21
      value: "# Disk DescriptorFile"
      name: "VMDK descriptor"
---

# VMware Virtual Machine Disk (VMDK)

VMDK is VMware's virtual disk format, used since the earliest VMware products.
It has evolved through several versions and sub-formats.

## Characteristics

- Multiple sub-formats (sparse, flat, descriptor)
- Sparse allocation
- Snapshots via delta disks
- Split files (2GB chunks for FAT32 compatibility)
- Maximum size: 62 TB (vSphere 8)
- ESXi uses different variants than Workstation

## Sub-formats

- **Sparse**: Single file with embedded grain tables
- **Flat**: Raw data with separate descriptor file
- **Split**: Multiple 2GB files
- **Stream-optimized**: Compressed, for OVA distribution
- **ESXi thin/thick**: Server-specific variants

## Structure (Sparse)

- Magic: `KDMV` (0x564d444b) or `VMDK` at offset 0
- Sparse header with grain size, capacity
- Grain directory and tables
- Data grains (default 64KB)

## Header Fields (Sparse)

| Offset | Size | Field                   |
|--------|------|-------------------------|
| 0x00   | 4    | Magic (KDMV)            |
| 0x04   | 4    | Version                 |
| 0x08   | 4    | Flags                   |
| 0x0C   | 8    | Capacity (sectors)      |
| 0x14   | 8    | Grain size (sectors)    |
| 0x1C   | 8    | Descriptor offset       |
| 0x24   | 8    | Descriptor size         |
| 0x2C   | 4    | Num grain table entries |
| 0x30   | 8    | Rgd offset              |
| 0x38   | 8    | Gd offset               |
| 0x40   | 8    | Overhead                |

## Descriptor File

Text file describing the virtual disk:

```
# Disk DescriptorFile
version=1
CID=fffffffe
parentCID=ffffffff
createType="monolithicSparse"

# Extent description
RW 41943040 SPARSE "disk.vmdk"

# The Disk Data Base
ddb.virtualHWVersion = "4"
ddb.geometry.cylinders = "2610"
```

## Detection

- Binary sparse: Magic `KDMV` at offset 0
- Descriptor: Text starting with `# Disk DescriptorFile`

## Tools

```sh
# Create VMDK
qemu-img create -f vmdk disk.vmdk 100G

# Convert to VMDK
qemu-img convert -f qcow2 -O vmdk disk.qcow2 disk.vmdk

# VMware tool
vmware-vdiskmanager -c -s 100GB -a lsilogic -t 0 disk.vmdk
```
