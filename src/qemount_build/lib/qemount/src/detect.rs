//! Format detection engine

use crate::container;
use crate::format::{Detect, Rule, Value, FORMATS};
use std::ffi::CStr;
use std::io;
use std::sync::Arc;

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
    match rule {
        Rule::Any { any } => any.iter().any(|r| matches_rule(reader, r)),
        Rule::All { all } => all.iter().all(|r| matches_rule(reader, r)),
        Rule::Leaf { offset, typ, value, op, mask, name: _, then_rules } => {
            matches_leaf(reader, *offset as u64, typ, value.as_ref(), op.as_deref(), *mask, then_rules.as_ref(), |r, rule| matches_rule(r, rule))
        }
    }
}

fn matches_leaf<R, F>(
    reader: &R,
    offset: u64,
    typ: &str,
    value: Option<&Value>,
    op: Option<&str>,
    mask: Option<u64>,
    then_rules: Option<&Vec<Rule>>,
    recurse: F,
) -> bool
where
    R: Reader + ?Sized,
    F: Fn(&R, &Rule) -> bool,
{
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

// Allow Reader to work with trait objects
impl Reader for &dyn Reader {
    fn read_at(&self, offset: u64, buf: &mut [u8]) -> io::Result<usize> {
        (*self).read_at(offset, buf)
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

/// Detect format tree recursively
///
/// Returns a list of root-level detected formats, each with their
/// children populated if they are container formats.
pub fn detect_tree(reader: Arc<dyn Reader + Send + Sync>) -> Vec<DetectNode> {
    detect_tree_recursive(reader, 0, 0)
}

fn detect_tree_recursive(reader: Arc<dyn Reader + Send + Sync>, index: u32, depth: u32) -> Vec<DetectNode> {
    if depth >= MAX_DEPTH {
        return vec![];
    }

    let formats = detect_all_dyn(&*reader);

    formats
        .into_iter()
        .map(|format| {
            let format_str = format.to_str().unwrap_or("");
            let children = match container::get_container(format_str) {
                Some(container) => match container.children(Arc::clone(&reader)) {
                    Ok(kids) => kids
                        .into_iter()
                        .flat_map(|child| {
                            detect_tree_recursive(child.reader, child.index, depth + 1)
                        })
                        .collect(),
                    Err(_) => vec![],
                },
                None => vec![],
            };

            DetectNode {
                format,
                index,
                children,
            }
        })
        .collect()
}

/// detect_all for trait objects
fn detect_all_dyn(reader: &dyn Reader) -> Vec<&'static CStr> {
    FORMATS
        .formats
        .iter()
        .filter(|(_, detect)| matches_detect_dyn(reader, detect))
        .map(|(name, _)| *name)
        .collect()
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
        Rule::Leaf { offset, typ, value, op, mask, name: _, then_rules } => {
            matches_leaf(reader, *offset as u64, typ, value.as_ref(), op.as_deref(), *mask, then_rules.as_ref(), |r, rule| matches_rule_dyn(r, rule))
        }
    }
}
