//! Checksum algorithms for format detection
//!
//! Registry of named checksum validators. Each validator takes a byte slice
//! and returns true if the checksum is valid.

/// Checksum validator function type
pub type ChecksumFn = fn(&[u8]) -> bool;

/// Get checksum validator by name
pub fn get(name: &str) -> Option<ChecksumFn> {
    match name {
        "adfs" => Some(adfs),
        "ics" => Some(ics),
        "powertec" => Some(powertec),
        _ => None,
    }
}

/// ADFS boot block checksum (carry-folding sum)
///
/// Iterates bytes 510→0, accumulating with carry folding.
/// Valid if (result & 0xff) == data[511].
pub fn adfs(data: &[u8]) -> bool {
    if data.len() < 512 {
        return false;
    }
    let mut result: u32 = 0;
    for i in (0..511).rev() {
        result = (result & 0xff) + (result >> 8) + data[i] as u32;
    }
    (result & 0xff) as u8 == data[511]
}

/// ICS checksum
///
/// sum(bytes[0..507]) + 0x50617274 ("Part") == le32(bytes[508..511])
pub fn ics(data: &[u8]) -> bool {
    if data.len() < 512 {
        return false;
    }
    let mut sum: u32 = 0x50617274; // "Part" in ASCII
    for &b in &data[..508] {
        sum = sum.wrapping_add(b as u32);
    }
    let stored = u32::from_le_bytes([data[508], data[509], data[510], data[511]]);
    sum == stored
}

/// PowerTec checksum
///
/// sum(bytes[0..510]) + 0x2a == byte[511]
/// Also rejects disks with MBR signature (0x55AA at 510-511).
pub fn powertec(data: &[u8]) -> bool {
    if data.len() < 512 {
        return false;
    }
    // Reject if looks like MBR
    if data[510] == 0x55 && data[511] == 0xaa {
        return false;
    }
    let mut checksum: u8 = 0x2a;
    for &b in &data[..511] {
        checksum = checksum.wrapping_add(b);
    }
    checksum == data[511]
}

/// XOR decrypt data with a repeating key
pub fn xor_decrypt(data: &[u8], key: &[u8]) -> Vec<u8> {
    if key.is_empty() {
        return data.to_vec();
    }
    data.iter()
        .enumerate()
        .map(|(i, &b)| b ^ key[i % key.len()])
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_registry() {
        assert!(get("adfs").is_some());
        assert!(get("ics").is_some());
        assert!(get("powertec").is_some());
        assert!(get("unknown").is_none());
    }

    #[test]
    fn test_xor_decrypt() {
        let data = b"Hello";
        let key = b"key";
        let encrypted = xor_decrypt(data, key);
        let decrypted = xor_decrypt(&encrypted, key);
        assert_eq!(decrypted, data);
    }
}
