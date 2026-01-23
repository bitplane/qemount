//! Format detection engine

use crate::checksum;
use crate::container;
use crate::format::{Detect, Rule, Value, FORMATS};
use regex::Regex;
use std::collections::HashSet;
use std::ffi::CStr;
use std::io;
use std::sync::Arc;

/// Trait for reading bytes at arbitrary offsets (pread-style).
/// Rust std has Read (sequential) and Seek (stateful) but no trait for
/// stateless positional reads. This mirrors FileExt::read_at() as a trait.
pub trait Reader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize>;
    fn size(&self) -> Option<u64>;
}

/// Resolve a potentially negative offset using file size.
/// Negative offsets are relative to end of file (e.g., -8 = 8 bytes from end).
fn resolve_offset(offset: i64, size: Option<u64>) -> Option<u64> {
    if offset >= 0 {
        Some(offset as u64)
    } else {
        size.map(|s| s.saturating_sub((-offset) as u64))
    }
}

fn matches_leaf<R, F>(
    reader: &R,
    offset: u64,
    typ: &str,
    value: Option<&Value>,
    op: Option<&str>,
    mask: Option<u64>,
    length: Option<u32>,
    then_rules: Option<&Vec<Rule>>,
    algorithm: Option<&str>,
    key: Option<&str>,
    recurse: F,
) -> bool
where
    R: Reader + ?Sized,
    F: Fn(&R, &Rule) -> bool,
{
    // Handle checksum type - validates checksum over a range
    if typ == "checksum" {
        let len = length.unwrap_or(512) as usize;
        let alg = algorithm.unwrap_or("adfs");
        return match_checksum(reader, offset, len, alg);
    }

    // Handle xor type - decrypts data and applies nested rules
    if typ == "xor" {
        let len = length.unwrap_or(256) as usize;
        let xor_key = key.unwrap_or("");
        return match_xor_then(reader, offset, len, xor_key, then_rules, &recurse);
    }

    // If no expected value, rule is extraction-only (always matches)
    let expected = match value {
        Some(v) => v,
        None => {
            if let Some(rules) = then_rules {
                return rules.iter().all(|r| recurse(reader, r));
            }
            return true;
        }
    };

    // Handle string type specially
    if typ == "string" {
        let matched = match match_bytes_generic(reader, offset, expected) {
            Some(m) => m,
            None => return false,
        };
        if matched {
            if let Some(rules) = then_rules {
                return rules.iter().all(|r| recurse(reader, r));
            }
        }
        return matched;
    }

    // Handle ascii type with regex pattern matching
    if typ == "ascii" {
        let len = match length {
            Some(l) => l as usize,
            None => return false, // length is required for ascii type
        };
        let pattern = match expected {
            Value::String(s) => s.as_str(),
            _ => return false,
        };
        let matched = match match_ascii_regex(reader, offset, len, pattern) {
            Some(m) => m,
            None => return false,
        };
        if matched {
            if let Some(rules) = then_rules {
                return rules.iter().all(|r| recurse(reader, r));
            }
        }
        return matched;
    }

    // Read value at offset based on type
    let actual = match read_value_generic(reader, offset, typ) {
        Some(v) => v,
        None => return false,
    };

    // Apply mask if present
    let actual = if let Some(m) = mask {
        match actual {
            Value::Int(i) => Value::Int(i & m as i64),
            v => v,
        }
    } else {
        actual
    };

    // Compare with operator
    let op = op.unwrap_or("=");
    let matches = compare(&actual, expected, op);

    // Check nested rules if match succeeded
    if matches {
        if let Some(rules) = then_rules {
            return rules.iter().all(|r| recurse(reader, r));
        }
    }

    matches
}

fn match_ascii_regex<R: Reader + ?Sized>(
    reader: &R,
    offset: u64,
    length: usize,
    pattern: &str,
) -> Option<bool> {
    let mut buf = vec![0u8; length];
    if reader.read_at(offset, &mut buf).ok()? != length {
        return Some(false);
    }
    // Check all bytes are ASCII
    if !buf.iter().all(|&b| b.is_ascii()) {
        return Some(false);
    }
    let s = std::str::from_utf8(&buf).ok()?;
    let re = Regex::new(pattern).ok()?;
    Some(re.is_match(s))
}

fn match_bytes_generic<R: Reader + ?Sized>(reader: &R, offset: u64, expected: &Value) -> Option<bool> {
    let expected_bytes = match expected {
        Value::Bytes(b) => b,
        _ => return None,
    };
    let expected_u8: Vec<u8> = expected_bytes.iter().map(|&x| x as u8).collect();
    let mut buf = vec![0u8; expected_u8.len()];
    match reader.read_at(offset, &mut buf) {
        Ok(n) if n == expected_u8.len() => Some(buf == expected_u8),
        _ => Some(false),
    }
}

fn read_value_generic<R: Reader + ?Sized>(reader: &R, offset: u64, typ: &str) -> Option<Value> {
    match typ {
        "byte" | "u8" | "i8" => read_byte_generic(reader, offset).map(|b| Value::Int(b as i64)),
        "le16" | "u16" | "i16" => read_le16_generic(reader, offset).map(|v| Value::Int(v as i64)),
        "be16" => read_be16_generic(reader, offset).map(|v| Value::Int(v as i64)),
        "le32" | "u32" | "i32" => read_le32_generic(reader, offset).map(|v| Value::Int(v as i64)),
        "be32" => read_be32_generic(reader, offset).map(|v| Value::Int(v as i64)),
        "le64" | "u64" | "i64" => read_le64_generic(reader, offset).map(|v| Value::Int(v as i64)),
        "be64" => read_be64_generic(reader, offset).map(|v| Value::Int(v as i64)),
        "string" => None,
        _ => None,
    }
}

fn read_byte_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u8> {
    let mut buf = [0u8; 1];
    match reader.read_at(offset, &mut buf) {
        Ok(1) => Some(buf[0]),
        _ => None,
    }
}

fn read_bytes_generic<R: Reader + ?Sized, const N: usize>(reader: &R, offset: u64) -> Option<[u8; N]> {
    let mut buf = [0u8; N];
    match reader.read_at(offset, &mut buf) {
        Ok(n) if n == N => Some(buf),
        _ => None,
    }
}

fn read_le16_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u64> {
    read_bytes_generic::<R, 2>(reader, offset).map(|b| u16::from_le_bytes(b) as u64)
}

fn read_le32_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u64> {
    read_bytes_generic::<R, 4>(reader, offset).map(|b| u32::from_le_bytes(b) as u64)
}

fn read_le64_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u64> {
    read_bytes_generic::<R, 8>(reader, offset).map(u64::from_le_bytes)
}

fn read_be16_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u64> {
    read_bytes_generic::<R, 2>(reader, offset).map(|b| u16::from_be_bytes(b) as u64)
}

fn read_be32_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u64> {
    read_bytes_generic::<R, 4>(reader, offset).map(|b| u32::from_be_bytes(b) as u64)
}

fn read_be64_generic<R: Reader + ?Sized>(reader: &R, offset: u64) -> Option<u64> {
    read_bytes_generic::<R, 8>(reader, offset).map(u64::from_be_bytes)
}

fn compare(actual: &Value, expected: &Value, op: &str) -> bool {
    match (actual, expected) {
        (Value::Int(a), Value::Int(e)) => match op {
            "=" => a == e,
            "!=" => a != e,
            "&" => (a & e) == *e,
            "^" => (a ^ e) == 0,
            "<" => a < e,
            ">" => a > e,
            "<=" => a <= e,
            ">=" => a >= e,
            _ => false,
        },
        (Value::Bytes(a), Value::Bytes(e)) => a == e,
        _ => false,
    }
}

/// Match checksum validation rule
fn match_checksum<R: Reader + ?Sized>(reader: &R, offset: u64, length: usize, algorithm: &str) -> bool {
    let validator = match checksum::get(algorithm) {
        Some(f) => f,
        None => return false,
    };
    let mut buf = vec![0u8; length];
    match reader.read_at(offset, &mut buf) {
        Ok(n) if n == length => validator(&buf),
        _ => false,
    }
}

/// Match xor decryption with nested rules
fn match_xor_then<R, F>(
    reader: &R,
    offset: u64,
    length: usize,
    key: &str,
    then_rules: Option<&Vec<Rule>>,
    recurse: &F,
) -> bool
where
    R: Reader + ?Sized,
    F: Fn(&R, &Rule) -> bool,
{
    let rules = match then_rules {
        Some(r) => r,
        None => return true, // No nested rules means xor alone matched
    };

    // Read and decrypt the data
    let mut buf = vec![0u8; length];
    match reader.read_at(offset, &mut buf) {
        Ok(n) if n == length => {}
        _ => return false,
    }
    let decrypted = checksum::xor_decrypt(&buf, key.as_bytes());

    // Create a reader for the decrypted data and check nested rules
    let decrypted_reader = crate::container::BytesReader::new(decrypted);
    rules.iter().all(|r| match r {
        Rule::Any { any } => any.iter().any(|r2| match_rule_on_bytes(&decrypted_reader, r2)),
        Rule::All { all } => all.iter().all(|r2| match_rule_on_bytes(&decrypted_reader, r2)),
        Rule::Leaf { .. } => match_rule_on_bytes(&decrypted_reader, r),
    })
}

/// Match a rule against a BytesReader (for xor nested rules)
fn match_rule_on_bytes(reader: &crate::container::BytesReader, rule: &Rule) -> bool {
    match rule {
        Rule::Any { any } => any.iter().any(|r| match_rule_on_bytes(reader, r)),
        Rule::All { all } => all.iter().all(|r| match_rule_on_bytes(reader, r)),
        Rule::Leaf { offset, typ, value, op, mask, name: _, then_rules, length, algorithm, key } => {
            let resolved = match resolve_offset(*offset, reader.size()) {
                Some(o) => o,
                None => return false,
            };
            matches_leaf(reader, resolved, typ, value.as_ref(), op.as_deref(), *mask, *length, then_rules.as_ref(), algorithm.as_deref(), key.as_deref(), |r, rule| match_rule_on_bytes(r, rule))
        }
    }
}

// Allow Reader to work with trait objects
impl Reader for &dyn Reader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        (*self).read_at(offset, buf)
    }
    fn size(&self) -> Option<u64> {
        (*self).size()
    }
}

/// A node in the detection tree
pub struct DetectNode {
    /// Detected format name (e.g., "arc/gzip", "fs/ext4")
    pub format: &'static CStr,
    /// Index within parent container (partition number, etc.)
    pub index: u32,
    /// Child nodes (for container formats)
    pub children: Vec<DetectNode>,
}

/// Maximum recursion depth for nested containers
const MAX_DEPTH: u32 = 16;

/// Fallback format for unrecognized data
static DATA_FORMAT: &std::ffi::CStr = c"data";

/// Check if format is a transform (creates new byte stream) vs slice (same bytes)
fn is_transform(format: &str) -> bool {
    format.starts_with("arc/")
}

/// Detect format tree recursively
///
/// Returns a list of root-level detected formats, each with their
/// children populated if they are container formats.
pub fn detect_tree(reader: Arc<dyn Reader + Send + Sync>) -> Vec<DetectNode> {
    let mut seen = HashSet::new();
    detect_tree_recursive(reader, 0, 0, String::new(), 0, &mut seen)
}

fn detect_tree_recursive(
    reader: Arc<dyn Reader + Send + Sync>,
    index: u32,
    depth: u32,
    stream: String,
    offset: u64,
    seen: &mut HashSet<(String, u64, &'static CStr)>,
) -> Vec<DetectNode> {
    if depth >= MAX_DEPTH {
        return vec![];
    }

    let mut results = Vec::new();

    // Iterate in priority order, processing each match immediately (depth-first)
    for (format, detect) in FORMATS.formats.iter() {
        if !matches_detect_dyn(&*reader, detect) {
            continue;
        }

        // Key by (stream, offset, format) - same bytes get deduped, different bytes don't
        if !seen.insert((stream.clone(), offset, *format)) {
            continue;
        }

        let format_str = format.to_str().unwrap_or("");
        let children = match container::get_container(format_str) {
            Some(container) => match container.children(Arc::clone(&reader)) {
                Ok(kids) => {
                    let child_stream = if is_transform(format_str) {
                        format!("{}/{}", stream, format_str)
                    } else {
                        stream.clone()
                    };
                    kids.into_iter()
                        .flat_map(|child| {
                            let detected = detect_tree_recursive(
                                Arc::clone(&child.reader),
                                child.index,
                                depth + 1,
                                child_stream.clone(),
                                child.offset,
                                seen,
                            );
                            // If nothing detected, emit "data" as fallback
                            if detected.is_empty() {
                                vec![DetectNode {
                                    format: DATA_FORMAT,
                                    index: child.index,
                                    children: vec![],
                                }]
                            } else {
                                detected
                            }
                        })
                        .collect()
                }
                Err(_) => vec![],
            },
            None => vec![],
        };

        results.push(DetectNode {
            format: *format,
            index,
            children,
        });
    }

    results
}

fn matches_detect_dyn(reader: &dyn Reader, detect: &Detect) -> bool {
    match detect {
        Detect::All { all } => all.iter().all(|r| matches_rule_dyn(reader, r)),
        Detect::Any { any } => any.iter().any(|r| matches_rule_dyn(reader, r)),
    }
}

fn matches_rule_dyn(reader: &dyn Reader, rule: &Rule) -> bool {
    match rule {
        Rule::Any { any } => any.iter().any(|r| matches_rule_dyn(reader, r)),
        Rule::All { all } => all.iter().all(|r| matches_rule_dyn(reader, r)),
        Rule::Leaf { offset, typ, value, op, mask, name: _, then_rules, length, algorithm, key } => {
            let resolved = match resolve_offset(*offset, reader.size()) {
                Some(o) => o,
                None => return false,
            };
            matches_leaf(reader, resolved, typ, value.as_ref(), op.as_deref(), *mask, *length, then_rules.as_ref(), algorithm.as_deref(), key.as_deref(), |r, rule| matches_rule_dyn(r, rule))
        }
    }
}
