//! Format detection engine

use crate::format::{Detect, Rule, Value, FORMATS};
use std::ffi::CStr;

pub fn detect(data: &[u8]) -> Option<&'static CStr> {
    for (name, detect) in &FORMATS.formats {
        if matches_detect(data, detect) {
            return Some(*name);
        }
    }
    None
}

fn matches_detect(data: &[u8], detect: &Detect) -> bool {
    match detect {
        Detect::All { all } => all.iter().all(|r| matches_rule(data, r)),
        Detect::Any { any } => any.iter().any(|r| matches_rule(data, r)),
    }
}

fn matches_rule(data: &[u8], rule: &Rule) -> bool {
    let offset = rule.offset as usize;

    // Read value at offset based on type
    let actual = match read_value(data, offset, &rule.typ) {
        Some(v) => v,
        None => return false,
    };

    // If no expected value, rule is extraction-only (always matches)
    let expected = match &rule.value {
        Some(v) => v,
        None => {
            // Check nested rules if present
            if let Some(then_rules) = &rule.then_rules {
                return then_rules.iter().all(|r| matches_rule(data, r));
            }
            return true;
        }
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
            return then_rules.iter().all(|r| matches_rule(data, r));
        }
    }

    matches
}

fn read_value(data: &[u8], offset: usize, typ: &str) -> Option<Value> {
    match typ {
        "byte" => data.get(offset).map(|&b| Value::Int(b as i64)),
        "le16" => read_le::<2>(data, offset).map(|v| Value::Int(v as i64)),
        "be16" => read_be::<2>(data, offset).map(|v| Value::Int(v as i64)),
        "le32" => read_le::<4>(data, offset).map(|v| Value::Int(v as i64)),
        "be32" => read_be::<4>(data, offset).map(|v| Value::Int(v as i64)),
        "le64" => read_le::<8>(data, offset).map(|v| Value::Int(v as i64)),
        "be64" => read_be::<8>(data, offset).map(|v| Value::Int(v as i64)),
        "string" => None, // Handled separately in compare
        _ => None,
    }
}

fn read_le<const N: usize>(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; N] = data.get(offset..offset + N)?.try_into().ok()?;
    Some(match N {
        2 => u16::from_le_bytes(bytes[..2].try_into().unwrap()) as u64,
        4 => u32::from_le_bytes(bytes[..4].try_into().unwrap()) as u64,
        8 => u64::from_le_bytes(bytes),
        _ => return None,
    })
}

fn read_be<const N: usize>(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; N] = data.get(offset..offset + N)?.try_into().ok()?;
    Some(match N {
        2 => u16::from_be_bytes(bytes[..2].try_into().unwrap()) as u64,
        4 => u32::from_be_bytes(bytes[..4].try_into().unwrap()) as u64,
        8 => u64::from_be_bytes(bytes),
        _ => return None,
    })
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
