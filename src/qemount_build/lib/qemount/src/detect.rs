//! Format detection engine

use crate::format::{Detect, Rule, Value, FORMATS};
use std::ffi::CStr;
use std::io;

/// Trait for reading bytes at arbitrary offsets (pread-style).
/// Rust std has Read (sequential) and Seek (stateful) but no trait for
/// stateless positional reads. This mirrors FileExt::read_at() as a trait.
pub trait Reader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize>;
}

/// Returns all matching format names
pub fn detect_all(reader: &impl Reader) -> Vec<&'static CStr> {
    FORMATS
        .formats
        .iter()
        .filter(|(_, detect)| matches_detect(reader, detect))
        .map(|(name, _)| *name)
        .collect()
}

fn matches_detect(reader: &impl Reader, detect: &Detect) -> bool {
    match detect {
        Detect::All { all } => all.iter().all(|r| matches_rule(reader, r)),
        Detect::Any { any } => any.iter().any(|r| matches_rule(reader, r)),
    }
}

fn matches_rule(reader: &impl Reader, rule: &Rule) -> bool {
    let offset = rule.offset as u64;

    // If no expected value, rule is extraction-only (always matches)
    let expected = match &rule.value {
        Some(v) => v,
        None => {
            // Check nested rules if present
            if let Some(then_rules) = &rule.then_rules {
                return then_rules.iter().all(|r| matches_rule(reader, r));
            }
            return true;
        }
    };

    // Handle string type specially - need expected length to read correct bytes
    if rule.typ == "string" {
        if let Value::Str(expected_str) = expected {
            return match_string(reader, offset, expected_str);
        }
        return false;
    }

    // Read value at offset based on type
    let actual = match read_value(reader, offset, &rule.typ) {
        Some(v) => v,
        None => return false,
    };

    // Apply mask if present
    let actual = if let Some(mask) = rule.mask {
        match actual {
            Value::Int(i) => Value::Int(i & mask as i64),
            v => v,
        }
    } else {
        actual
    };

    // Compare with operator
    let op = rule.op.as_deref().unwrap_or("=");
    let matches = compare(&actual, expected, op);

    // Check nested rules if match succeeded
    if matches {
        if let Some(then_rules) = &rule.then_rules {
            return then_rules.iter().all(|r| matches_rule(reader, r));
        }
    }

    matches
}

fn match_string(reader: &impl Reader, offset: u64, expected: &str) -> bool {
    let expected_bytes = expected.as_bytes();
    let mut buf = vec![0u8; expected_bytes.len()];
    match reader.read_at(offset, &mut buf) {
        Ok(n) if n == expected_bytes.len() => buf == expected_bytes,
        _ => false,
    }
}

fn read_value(reader: &impl Reader, offset: u64, typ: &str) -> Option<Value> {
    match typ {
        "byte" => read_byte(reader, offset).map(|b| Value::Int(b as i64)),
        "le16" => read_le16(reader, offset).map(|v| Value::Int(v as i64)),
        "be16" => read_be16(reader, offset).map(|v| Value::Int(v as i64)),
        "le32" => read_le32(reader, offset).map(|v| Value::Int(v as i64)),
        "be32" => read_be32(reader, offset).map(|v| Value::Int(v as i64)),
        "le64" => read_le64(reader, offset).map(|v| Value::Int(v as i64)),
        "be64" => read_be64(reader, offset).map(|v| Value::Int(v as i64)),
        "string" => None, // Handled separately in compare
        _ => None,
    }
}

fn read_byte(reader: &impl Reader, offset: u64) -> Option<u8> {
    let mut buf = [0u8; 1];
    match reader.read_at(offset, &mut buf) {
        Ok(1) => Some(buf[0]),
        _ => None,
    }
}

fn read_bytes<const N: usize>(reader: &impl Reader, offset: u64) -> Option<[u8; N]> {
    let mut buf = [0u8; N];
    match reader.read_at(offset, &mut buf) {
        Ok(n) if n == N => Some(buf),
        _ => None,
    }
}

fn read_le16(reader: &impl Reader, offset: u64) -> Option<u64> {
    read_bytes::<2>(reader, offset).map(|b| u16::from_le_bytes(b) as u64)
}

fn read_le32(reader: &impl Reader, offset: u64) -> Option<u64> {
    read_bytes::<4>(reader, offset).map(|b| u32::from_le_bytes(b) as u64)
}

fn read_le64(reader: &impl Reader, offset: u64) -> Option<u64> {
    read_bytes::<8>(reader, offset).map(u64::from_le_bytes)
}

fn read_be16(reader: &impl Reader, offset: u64) -> Option<u64> {
    read_bytes::<2>(reader, offset).map(|b| u16::from_be_bytes(b) as u64)
}

fn read_be32(reader: &impl Reader, offset: u64) -> Option<u64> {
    read_bytes::<4>(reader, offset).map(|b| u32::from_be_bytes(b) as u64)
}

fn read_be64(reader: &impl Reader, offset: u64) -> Option<u64> {
    read_bytes::<8>(reader, offset).map(u64::from_be_bytes)
}

fn compare(actual: &Value, expected: &Value, op: &str) -> bool {
    match (actual, expected) {
        (Value::Int(a), Value::Int(e)) => match op {
            "=" => a == e,
            "&" => (a & e) == *e,
            "^" => (a ^ e) == 0,
            "<" => a < e,
            ">" => a > e,
            "<=" => a <= e,
            ">=" => a >= e,
            _ => false,
        },
        (Value::Str(a), Value::Str(e)) => a == e,
        _ => false,
    }
}
