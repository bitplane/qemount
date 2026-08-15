//! DMS (Disk Masher System) disk image reader
//!
//! Decompresses Amiga DMS compressed floppy disk images to raw ADF format.
//! Ported from xDMS v1.3 by Andre Rodrigues de la Rocha (Public Domain).

use crate::container::{read_all, BytesReader, Child, Container};
use crate::detect::Reader;
use std::io;
use std::sync::Arc;

// ---- Constants ----

const ADF_SIZE: usize = 901120; // 80 cyl * 2 heads * 11 sectors * 512 bytes
const HEADLEN: usize = 56;
const THLEN: usize = 20;
const TRACK_BUFFER_LEN: usize = 32000;

// Deep mode constants
const F: u16 = 60; // lookahead buffer size
const THRESHOLD: u16 = 2;
const N_CHAR: u16 = 256 - THRESHOLD + F; // 314
const T: u16 = N_CHAR * 2 - 1; // 627
const R: u16 = T - 1; // 626
const MAX_FREQ: u16 = 0x8000;

// Heavy mode constants
const NC: usize = 510;
const NPT: usize = 20;
const N1: u16 = 510;
const OFFSET: u16 = 253;

// ---- CRC-16 table (from xDMS crc_csum.c, by Bjorn Stenberg) ----

static CRC_TABLE: [u16; 256] = [
    0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
    0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
    0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
    0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
    0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
    0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
    0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
    0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
    0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
    0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
    0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
    0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
    0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
    0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
    0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
    0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
    0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
    0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
    0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
    0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
    0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
    0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
    0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
    0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
    0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
    0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
    0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
    0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
    0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
    0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
    0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
    0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040,
];

// ---- Distance decoding tables (from xDMS tables.c) ----

static D_CODE: [u8; 256] = [
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
    0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
    0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,
    0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
    0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09,
    0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A,
    0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B,
    0x0C, 0x0C, 0x0C, 0x0C, 0x0D, 0x0D, 0x0D, 0x0D,
    0x0E, 0x0E, 0x0E, 0x0E, 0x0F, 0x0F, 0x0F, 0x0F,
    0x10, 0x10, 0x10, 0x10, 0x11, 0x11, 0x11, 0x11,
    0x12, 0x12, 0x12, 0x12, 0x13, 0x13, 0x13, 0x13,
    0x14, 0x14, 0x14, 0x14, 0x15, 0x15, 0x15, 0x15,
    0x16, 0x16, 0x16, 0x16, 0x17, 0x17, 0x17, 0x17,
    0x18, 0x18, 0x19, 0x19, 0x1A, 0x1A, 0x1B, 0x1B,
    0x1C, 0x1C, 0x1D, 0x1D, 0x1E, 0x1E, 0x1F, 0x1F,
    0x20, 0x20, 0x21, 0x21, 0x22, 0x22, 0x23, 0x23,
    0x24, 0x24, 0x25, 0x25, 0x26, 0x26, 0x27, 0x27,
    0x28, 0x28, 0x29, 0x29, 0x2A, 0x2A, 0x2B, 0x2B,
    0x2C, 0x2C, 0x2D, 0x2D, 0x2E, 0x2E, 0x2F, 0x2F,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
];

static D_LEN: [u8; 256] = [
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
    0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
    0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
];

// ---- Bit reader ----

struct BitReader<'a> {
    data: &'a [u8],
    pos: usize,
    bitbuf: u32,
    bitcount: u32,
}

impl<'a> BitReader<'a> {
    fn new(data: &'a [u8]) -> Self {
        let mut br = BitReader {
            data,
            pos: 0,
            bitbuf: 0,
            bitcount: 0,
        };
        br.fill();
        br
    }

    fn fill(&mut self) {
        while self.bitcount < 16 {
            let byte = if self.pos < self.data.len() {
                let b = self.data[self.pos];
                self.pos += 1;
                b
            } else {
                0
            };
            self.bitbuf = (self.bitbuf << 8) | byte as u32;
            self.bitcount += 8;
        }
    }

    /// Peek at the top n bits without consuming
    fn peek(&self, n: u32) -> u16 {
        (self.bitbuf >> (self.bitcount - n)) as u16
    }

    /// Drop n bits and refill
    fn drop(&mut self, n: u32) {
        self.bitcount -= n;
        self.bitbuf &= (1u32 << self.bitcount).wrapping_sub(1);
        self.fill();
    }

    /// Get n bits (peek + drop)
    fn get(&mut self, n: u32) -> u16 {
        let v = self.peek(n);
        self.drop(n);
        v
    }
}

// ---- CRC and checksum ----

fn crc16(data: &[u8]) -> u16 {
    let mut crc: u16 = 0;
    for &b in data {
        crc = CRC_TABLE[((crc ^ b as u16) & 0xff) as usize] ^ ((crc >> 8) & 0xff);
    }
    crc
}

fn checksum(data: &[u8]) -> u16 {
    let mut sum: u32 = 0;
    for &b in data {
        sum += b as u32;
    }
    (sum & 0xffff) as u16
}

// ---- Decompressor state ----

struct DmsState {
    // Shared 16KB text buffer (ring/sliding window)
    text: [u8; 0x4000],

    // Per-mode buffer positions (persist across tracks)
    quick_text_loc: u16,
    medium_text_loc: u16,
    deep_text_loc: u16,
    heavy_text_loc: u16,

    // Deep mode dynamic Huffman tree
    freq: [u16; T as usize + 1],
    prnt: [u16; T as usize + N_CHAR as usize],
    son: [u16; T as usize],
    init_deep_tabs: bool,

    // Heavy mode
    left: [u16; 2 * NC - 1],
    right: [u16; 2 * NC - 1 + 9],
    c_len: [u8; NC],
    pt_len: [u8; NPT],
    c_table: [u16; 4096],
    pt_table: [u16; 256],
    lastlen: u16,
    np: u16,
}

impl DmsState {
    fn new() -> Self {
        let mut s = DmsState {
            text: [0; 0x4000],
            quick_text_loc: 251,
            medium_text_loc: 0x3fbe,
            deep_text_loc: 0x3fc4,
            heavy_text_loc: 0,
            freq: [0; T as usize + 1],
            prnt: [0; T as usize + N_CHAR as usize],
            son: [0; T as usize],
            init_deep_tabs: true,
            left: [0; 2 * NC - 1],
            right: [0; 2 * NC - 1 + 9],
            c_len: [0; NC],
            pt_len: [0; NPT],
            c_table: [0; 4096],
            pt_table: [0; 256],
            lastlen: 0,
            np: 0,
        };
        // Zero only the first 0x3fc8 bytes, matching xDMS Init_Decrunchers
        s.text[..0x3fc8].fill(0);
        s
    }

    fn reinit(&mut self) {
        self.quick_text_loc = 251;
        self.medium_text_loc = 0x3fbe;
        self.deep_text_loc = 0x3fc4;
        self.heavy_text_loc = 0;
        self.init_deep_tabs = true;
        self.text[..0x3fc8].fill(0);
    }

    // ---- Mode 1: RLE ----

    fn unpack_rle(&self, input: &[u8], output: &mut Vec<u8>, origsize: usize) -> io::Result<()> {
        let mut ip = 0;
        let start = output.len();
        let target = start + origsize;

        while output.len() < target {
            if ip >= input.len() {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "RLE: unexpected end of input"));
            }
            let a = input[ip];
            ip += 1;
            if a != 0x90 {
                output.push(a);
            } else {
                if ip >= input.len() {
                    return Err(io::Error::new(io::ErrorKind::InvalidData, "RLE: unexpected end of input"));
                }
                let b = input[ip];
                ip += 1;
                if b == 0 {
                    output.push(0x90);
                } else {
                    if ip >= input.len() {
                        return Err(io::Error::new(io::ErrorKind::InvalidData, "RLE: unexpected end of input"));
                    }
                    let fill = input[ip];
                    ip += 1;
                    let n = if b == 0xff {
                        if ip + 1 >= input.len() {
                            return Err(io::Error::new(io::ErrorKind::InvalidData, "RLE: unexpected end of input"));
                        }
                        let hi = input[ip] as usize;
                        ip += 1;
                        let lo = input[ip] as usize;
                        ip += 1;
                        (hi << 8) + lo
                    } else {
                        b as usize
                    };
                    if output.len() + n > target {
                        return Err(io::Error::new(io::ErrorKind::InvalidData, "RLE: output overflow"));
                    }
                    output.extend(std::iter::repeat_n(fill, n));
                }
            }
        }
        Ok(())
    }

    // ---- Mode 2: Quick ----

    fn unpack_quick(&mut self, input: &[u8], output: &mut [u8]) {
        let mut br = BitReader::new(input);
        let mut op = 0;

        while op < output.len() {
            if br.peek(1) != 0 {
                br.drop(1);
                let c = br.get(8) as u8;
                self.text[(self.quick_text_loc & 0xff) as usize] = c;
                self.quick_text_loc = self.quick_text_loc.wrapping_add(1);
                output[op] = c;
                op += 1;
            } else {
                br.drop(1);
                let j = br.get(2) + 2;
                let mut i = self.quick_text_loc.wrapping_sub(br.get(8)).wrapping_sub(1);
                for _ in 0..j {
                    let c = self.text[(i & 0xff) as usize];
                    i = i.wrapping_add(1);
                    self.text[(self.quick_text_loc & 0xff) as usize] = c;
                    self.quick_text_loc = self.quick_text_loc.wrapping_add(1);
                    output[op] = c;
                    op += 1;
                    if op >= output.len() {
                        break;
                    }
                }
            }
        }
        self.quick_text_loc = (self.quick_text_loc + 5) & 0xff;
    }

    // ---- Mode 3: Medium ----

    fn unpack_medium(&mut self, input: &[u8], output: &mut [u8]) {
        let mut br = BitReader::new(input);
        let mut op = 0;

        while op < output.len() {
            if br.peek(1) != 0 {
                br.drop(1);
                let c = br.get(8) as u8;
                self.text[(self.medium_text_loc & 0x3fff) as usize] = c;
                self.medium_text_loc = self.medium_text_loc.wrapping_add(1);
                output[op] = c;
                op += 1;
            } else {
                br.drop(1);
                let mut c = br.get(8);
                let j = D_CODE[c as usize] as u16 + 3;
                let u = D_LEN[c as usize] as u32;
                c = ((c << u) | br.get(u)) & 0xff;
                br.drop(0); // bits already consumed by get()
                let u2 = D_LEN[c as usize] as u32;
                c = ((D_CODE[c as usize] as u16) << 8) | (((c << u2) | br.get(u2)) & 0xff);
                let mut i = self.medium_text_loc.wrapping_sub(c).wrapping_sub(1);

                for _ in 0..j {
                    let b = self.text[(i & 0x3fff) as usize];
                    i = i.wrapping_add(1);
                    self.text[(self.medium_text_loc & 0x3fff) as usize] = b;
                    self.medium_text_loc = self.medium_text_loc.wrapping_add(1);
                    output[op] = b;
                    op += 1;
                    if op >= output.len() {
                        break;
                    }
                }
            }
        }
        self.medium_text_loc = (self.medium_text_loc + 66) & 0x3fff;
    }

    // ---- Mode 4: Deep (dynamic Huffman) ----

    fn init_deep_tabs(&mut self) {
        let n = N_CHAR as usize;
        let t = T as usize;
        for i in 0..n {
            self.freq[i] = 1;
            self.son[i] = (i + t) as u16;
            self.prnt[i + t] = i as u16;
        }
        let mut i = 0usize;
        let mut j = n;
        while j <= R as usize {
            self.freq[j] = self.freq[i] + self.freq[i + 1];
            self.son[j] = i as u16;
            self.prnt[i] = j as u16;
            self.prnt[i + 1] = j as u16;
            i += 2;
            j += 1;
        }
        self.freq[t] = 0xffff;
        self.prnt[R as usize] = 0;
        self.init_deep_tabs = false;
    }

    fn deep_reconst(&mut self) {
        let t = T as usize;
        // Collect leaf nodes and halve frequencies
        let mut j = 0usize;
        for i in 0..t {
            if self.son[i] >= T {
                self.freq[j] = (self.freq[i] + 1) / 2;
                self.son[j] = self.son[i];
                j += 1;
            }
        }
        // Rebuild tree by connecting sons
        let n = N_CHAR as usize;
        let mut i = 0usize;
        let mut j2 = n;
        while j2 < t {
            let k = i + 1;
            let f = self.freq[i] + self.freq[k];
            self.freq[j2] = f;
            // Find insertion point
            let mut kk = j2 - 1;
            while f < self.freq[kk] {
                kk -= 1;
            }
            kk += 1;
            let l = j2 - kk;
            // Shift freq and son arrays
            if l > 0 {
                self.freq.copy_within(kk..kk + l, kk + 1);
                self.son.copy_within(kk..kk + l, kk + 1);
            }
            self.freq[kk] = f;
            self.son[kk] = i as u16;
            i += 2;
            j2 += 1;
        }
        // Reconnect parent pointers
        for i in 0..t {
            let k = self.son[i] as usize;
            if k >= t {
                self.prnt[k] = i as u16;
            } else {
                self.prnt[k] = i as u16;
                self.prnt[k + 1] = i as u16;
            }
        }
    }

    fn deep_update(&mut self, c: u16) {
        if self.freq[R as usize] == MAX_FREQ {
            self.deep_reconst();
        }
        let mut c_idx = self.prnt[(c + T) as usize] as usize;
        loop {
            self.freq[c_idx] += 1;
            let k = self.freq[c_idx];

            // Check if order is disturbed
            let mut l = c_idx + 1;
            if k > self.freq[l] {
                while k > self.freq[l + 1] {
                    l += 1;
                }
                // l now points to the last node with freq < k
                self.freq[c_idx] = self.freq[l];
                self.freq[l] = k;

                let i = self.son[c_idx] as usize;
                self.prnt[i] = l as u16;
                if i < T as usize {
                    self.prnt[i + 1] = l as u16;
                }

                let j = self.son[l] as usize;
                self.son[l] = i as u16;

                self.prnt[j] = c_idx as u16;
                if j < T as usize {
                    self.prnt[j + 1] = c_idx as u16;
                }
                self.son[c_idx] = j as u16;

                c_idx = l;
            }
            let p = self.prnt[c_idx] as usize;
            if p == 0 {
                break;
            }
            c_idx = p;
        }
    }

    fn deep_decode_char(&mut self, br: &mut BitReader) -> u16 {
        let mut c = self.son[R as usize];
        while c < T {
            c = self.son[c as usize + br.get(1) as usize];
        }
        let c = c - T;
        self.deep_update(c);
        c
    }

    fn deep_decode_position(br: &mut BitReader) -> u16 {
        let i = br.get(8);
        let c = (D_CODE[i as usize] as u16) << 8;
        let j = D_LEN[i as usize] as u32;
        let i2 = ((i << j) | br.get(j)) & 0xff;
        c | i2
    }

    fn unpack_deep(&mut self, input: &[u8], output: &mut [u8]) {
        let mut br = BitReader::new(input);

        if self.init_deep_tabs {
            self.init_deep_tabs();
        }

        let mut op = 0;
        while op < output.len() {
            let c = self.deep_decode_char(&mut br);
            if c < 256 {
                let byte = c as u8;
                self.text[(self.deep_text_loc & 0x3fff) as usize] = byte;
                self.deep_text_loc = self.deep_text_loc.wrapping_add(1);
                output[op] = byte;
                op += 1;
            } else {
                let j = c - 255 + THRESHOLD;
                let mut i = self.deep_text_loc.wrapping_sub(Self::deep_decode_position(&mut br)).wrapping_sub(1);
                for _ in 0..j {
                    let b = self.text[(i & 0x3fff) as usize];
                    i = i.wrapping_add(1);
                    self.text[(self.deep_text_loc & 0x3fff) as usize] = b;
                    self.deep_text_loc = self.deep_text_loc.wrapping_add(1);
                    output[op] = b;
                    op += 1;
                    if op >= output.len() {
                        break;
                    }
                }
            }
        }
        self.deep_text_loc = (self.deep_text_loc + 60) & 0x3fff;
    }

    // ---- Mode 5/6: Heavy (LZH) ----

    fn make_table(
        nchar: u16,
        bitlen: &[u8],
        tablebits: u16,
        table: &mut [u16],
        left: &mut [u16],
        right: &mut [u16],
    ) -> io::Result<()> {
        struct MkTbl<'a> {
            n: u16,
            blen: &'a [u8],
            tbl: &'a mut [u16],
            left: &'a mut [u16],
            right: &'a mut [u16],
            tblsiz: u16,
            bit: u16,
            maxdepth: u16,
            depth: u16,
            len: u16,
            c: i16,
            codeword: u16,
            avail: u16,
        }

        fn mktbl(s: &mut MkTbl) -> io::Result<u16> {
            let mut i: u16 = 0;

            if s.len == s.depth {
                loop {
                    s.c += 1;
                    if s.c >= s.n as i16 {
                        break;
                    }
                    if s.blen[s.c as usize] == s.len as u8 {
                        i = s.codeword;
                        s.codeword += s.bit;
                        if s.codeword > s.tblsiz {
                            return Err(io::Error::new(io::ErrorKind::InvalidData, "Heavy: table overflow"));
                        }
                        while i < s.codeword {
                            s.tbl[i as usize] = s.c as u16;
                            i += 1;
                        }
                        return Ok(s.c as u16);
                    }
                }
                s.c = -1;
                s.len += 1;
                s.bit >>= 1;
            }
            s.depth += 1;
            if s.depth < s.maxdepth {
                mktbl(s)?;
                mktbl(s)?;
            } else if s.depth > 32 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "Heavy: table depth exceeded"));
            } else {
                i = s.avail;
                s.avail += 1;
                if i as usize >= 2 * s.n as usize - 1 {
                    return Err(io::Error::new(io::ErrorKind::InvalidData, "Heavy: table avail exceeded"));
                }
                s.left[i as usize] = mktbl(s)?;
                s.right[i as usize] = mktbl(s)?;
                if s.codeword >= s.tblsiz {
                    return Err(io::Error::new(io::ErrorKind::InvalidData, "Heavy: codeword overflow"));
                }
                if s.depth == s.maxdepth {
                    s.tbl[s.codeword as usize] = i;
                    s.codeword += 1;
                }
            }
            s.depth -= 1;
            Ok(i)
        }

        let tblsiz = 1u16 << tablebits;
        let mut state = MkTbl {
            n: nchar,
            blen: bitlen,
            tbl: table,
            left,
            right,
            tblsiz,
            bit: tblsiz / 2,
            maxdepth: tablebits + 1,
            depth: 1,
            len: 1,
            c: -1,
            codeword: 0,
            avail: nchar,
        };

        mktbl(&mut state)?; // left subtree
        mktbl(&mut state)?; // right subtree
        if state.codeword != tblsiz {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Heavy: incomplete table"));
        }
        Ok(())
    }

    fn heavy_read_tree_c(&mut self, br: &mut BitReader) -> io::Result<()> {
        let n = br.get(9) as usize;
        if n > 0 {
            for i in 0..n.min(NC) {
                self.c_len[i] = br.get(5) as u8;
            }
            for i in n..NC {
                self.c_len[i] = 0;
            }
            Self::make_table(
                NC as u16,
                &self.c_len,
                12,
                &mut self.c_table,
                &mut self.left,
                &mut self.right,
            )?;
        } else {
            let n = br.get(9);
            self.c_len.fill(0);
            self.c_table.fill(n);
        }
        Ok(())
    }

    fn heavy_read_tree_p(&mut self, br: &mut BitReader) -> io::Result<()> {
        let n = br.get(5) as usize;
        if n > 0 {
            for i in 0..n.min(NPT) {
                self.pt_len[i] = br.get(4) as u8;
            }
            for i in n..self.np as usize {
                self.pt_len[i] = 0;
            }
            Self::make_table(
                self.np,
                &self.pt_len,
                8,
                &mut self.pt_table,
                &mut self.left,
                &mut self.right,
            )?;
        } else {
            let n = br.get(5);
            self.pt_len[..self.np as usize].fill(0);
            self.pt_table.fill(n);
        }
        Ok(())
    }

    fn heavy_decode_c(&self, br: &mut BitReader) -> u16 {
        let mut j = self.c_table[br.peek(12) as usize];
        if j < N1 {
            br.drop(self.c_len[j as usize] as u32);
        } else {
            br.drop(12);
            let i = br.peek(16);
            let mut m: u16 = 0x8000;
            loop {
                if i & m != 0 {
                    j = self.right[j as usize];
                } else {
                    j = self.left[j as usize];
                }
                m >>= 1;
                if j < N1 {
                    break;
                }
            }
            br.drop(self.c_len[j as usize] as u32 - 12);
        }
        j
    }

    fn heavy_decode_p(&mut self, br: &mut BitReader) -> u16 {
        let mut j = self.pt_table[br.peek(8) as usize];
        if j < self.np {
            br.drop(self.pt_len[j as usize] as u32);
        } else {
            br.drop(8);
            let i = br.peek(16);
            let mut m: u16 = 0x8000;
            loop {
                if i & m != 0 {
                    j = self.right[j as usize];
                } else {
                    j = self.left[j as usize];
                }
                m >>= 1;
                if j < self.np {
                    break;
                }
            }
            br.drop(self.pt_len[j as usize] as u32 - 8);
        }

        if j != self.np - 1 {
            if j > 0 {
                let i = j - 1;
                j = br.get(i as u32) | (1u16 << (j - 1));
            }
            self.lastlen = j;
        }

        self.lastlen
    }

    fn unpack_heavy(&mut self, input: &[u8], output: &mut [u8], flags: u8) -> io::Result<()> {
        let bitmask: u16;
        if flags & 8 != 0 {
            self.np = 15;
            bitmask = 0x1fff;
        } else {
            self.np = 14;
            bitmask = 0x0fff;
        }

        let mut br = BitReader::new(input);

        if flags & 2 != 0 {
            self.heavy_read_tree_c(&mut br)?;
            self.heavy_read_tree_p(&mut br)?;
        }

        let mut op = 0;
        while op < output.len() {
            let c = self.heavy_decode_c(&mut br);
            if c < 256 {
                let byte = c as u8;
                self.text[(self.heavy_text_loc & bitmask) as usize] = byte;
                self.heavy_text_loc = self.heavy_text_loc.wrapping_add(1);
                output[op] = byte;
                op += 1;
            } else {
                let j = c - OFFSET;
                let mut i = self.heavy_text_loc.wrapping_sub(self.heavy_decode_p(&mut br)).wrapping_sub(1);
                for _ in 0..j {
                    let b = self.text[(i & bitmask) as usize];
                    i = i.wrapping_add(1);
                    self.text[(self.heavy_text_loc & bitmask) as usize] = b;
                    self.heavy_text_loc = self.heavy_text_loc.wrapping_add(1);
                    output[op] = b;
                    op += 1;
                    if op >= output.len() {
                        break;
                    }
                }
            }
        }
        Ok(())
    }

    // ---- Track unpacking dispatcher ----

    fn unpack_track(
        &mut self,
        b1: &[u8],
        b2: &mut Vec<u8>,
        pklen2: usize,
        unpklen: usize,
        cmode: u8,
        flags: u8,
    ) -> io::Result<()> {
        match cmode {
            0 => {
                // No compression
                b2.extend_from_slice(&b1[..unpklen.min(b1.len())]);
            }
            1 => {
                // Simple RLE
                self.unpack_rle(b1, b2, unpklen)?;
            }
            2 => {
                // Quick + RLE
                let mut tmp = vec![0u8; pklen2];
                self.unpack_quick(b1, &mut tmp);
                self.unpack_rle(&tmp, b2, unpklen)?;
            }
            3 => {
                // Medium + RLE
                let mut tmp = vec![0u8; pklen2];
                self.unpack_medium(b1, &mut tmp);
                self.unpack_rle(&tmp, b2, unpklen)?;
            }
            4 => {
                // Deep + RLE
                let mut tmp = vec![0u8; pklen2];
                self.unpack_deep(b1, &mut tmp);
                self.unpack_rle(&tmp, b2, unpklen)?;
            }
            5 => {
                // Heavy 1
                let mut tmp = vec![0u8; pklen2];
                self.unpack_heavy(b1, &mut tmp, flags & 7)?;
                if flags & 4 != 0 {
                    self.unpack_rle(&tmp, b2, unpklen)?;
                } else {
                    b2.extend_from_slice(&tmp[..unpklen.min(tmp.len())]);
                }
            }
            6 => {
                // Heavy 2
                let mut tmp = vec![0u8; pklen2];
                self.unpack_heavy(b1, &mut tmp, flags | 8)?;
                if flags & 4 != 0 {
                    self.unpack_rle(&tmp, b2, unpklen)?;
                } else {
                    b2.extend_from_slice(&tmp[..unpklen.min(tmp.len())]);
                }
            }
            _ => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("DMS: unknown compression mode {cmode}"),
                ));
            }
        }

        // If flag bit 0 is NOT set, reinitialize decompressors
        if flags & 1 == 0 {
            self.reinit();
        }

        Ok(())
    }
}

// ---- Main decompression ----

fn decompress_dms(data: &[u8]) -> io::Result<Vec<u8>> {
    if data.len() < HEADLEN {
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            "DMS: file too short for header",
        ));
    }

    // Validate magic
    if &data[0..4] != b"DMS!" {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "DMS: invalid magic",
        ));
    }

    // Validate header CRC (CRC of bytes 4..54, compared to bytes 54..56)
    let hcrc = (data[HEADLEN - 2] as u16) << 8 | data[HEADLEN - 1] as u16;
    if crc16(&data[4..HEADLEN - 2]) != hcrc {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "DMS: header CRC mismatch",
        ));
    }

    let geninfo = (data[10] as u16) << 8 | data[11] as u16;

    // Reject encrypted files
    if geninfo & 2 != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Unsupported,
            "DMS: encrypted archives not supported",
        ));
    }

    // Reject FMS archives
    let disktype = (data[50] as u16) << 8 | data[51] as u16;
    if disktype == 7 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "DMS: FMS archives not supported",
        ));
    }

    let mut output = vec![0u8; ADF_SIZE];
    let mut state = Box::new(DmsState::new());
    let mut pos = HEADLEN;

    loop {
        // Read track header
        if pos + THLEN > data.len() {
            break; // End of file
        }
        let th = &data[pos..pos + THLEN];

        // Check for track header magic
        if th[0] != b'T' || th[1] != b'R' {
            break; // Not a track header, assume end of valid data
        }

        // Validate track header CRC
        let thcrc = (th[THLEN - 2] as u16) << 8 | th[THLEN - 1] as u16;
        if crc16(&th[..THLEN - 2]) != thcrc {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "DMS: track header CRC mismatch",
            ));
        }

        let number = (th[2] as u16) << 8 | th[3] as u16;
        let pklen1 = ((th[6] as u16) << 8 | th[7] as u16) as usize;
        let pklen2 = ((th[8] as u16) << 8 | th[9] as u16) as usize;
        let unpklen = ((th[10] as u16) << 8 | th[11] as u16) as usize;
        let flags = th[12];
        let cmode = th[13];
        let usum = (th[14] as u16) << 8 | th[15] as u16;
        let dcrc = (th[16] as u16) << 8 | th[17] as u16;

        pos += THLEN;

        // Validate track data size
        if pklen1 > TRACK_BUFFER_LEN || pklen2 > TRACK_BUFFER_LEN || unpklen > TRACK_BUFFER_LEN {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "DMS: track data too large",
            ));
        }

        if pos + pklen1 > data.len() {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "DMS: unexpected end of track data",
            ));
        }

        let track_data = &data[pos..pos + pklen1];
        pos += pklen1;

        // Validate track data CRC
        if crc16(track_data) != dcrc {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "DMS: track data CRC mismatch",
            ));
        }

        // Skip non-disk tracks (banners, FILEID.DIZ, fake boot blocks)
        if number >= 80 || unpklen <= 2048 {
            continue;
        }

        // Decompress track
        let mut unpacked = Vec::with_capacity(unpklen);
        state.unpack_track(track_data, &mut unpacked, pklen2, unpklen, cmode, flags)?;

        // Validate checksum
        if unpacked.len() >= unpklen && checksum(&unpacked[..unpklen]) != usum {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "DMS: track checksum mismatch after decompression",
            ));
        }

        // Copy decompressed data to output at correct position
        let track_offset = number as usize * 11 * 512; // 11 sectors per track * 512 bytes
        if track_offset + unpklen <= ADF_SIZE {
            let copy_len = unpklen.min(unpacked.len());
            output[track_offset..track_offset + copy_len].copy_from_slice(&unpacked[..copy_len]);
        }
    }

    Ok(output)
}

// ---- Container implementation ----

pub struct DmsContainer;

pub static DMS: DmsContainer = DmsContainer;

impl Container for DmsContainer {
    fn children(&self, reader: Arc<dyn Reader + Send + Sync>) -> io::Result<Vec<Child>> {
        let data = read_all(&*reader)?;
        let decompressed = decompress_dms(&data)?;
        Ok(vec![Child {
            index: 0,
            offset: u64::MAX, // Transformed data, not a slice
            reader: Arc::new(BytesReader::new(decompressed)),
        }])
    }
}
