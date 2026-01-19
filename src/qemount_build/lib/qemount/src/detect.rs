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
        "le16" => read_le16(data, offset).map(|v| Value::Int(v as i64)),
        "be16" => read_be16(data, offset).map(|v| Value::Int(v as i64)),
        "le32" => read_le32(data, offset).map(|v| Value::Int(v as i64)),
        "be32" => read_be32(data, offset).map(|v| Value::Int(v as i64)),
        "le64" => read_le64(data, offset).map(|v| Value::Int(v as i64)),
        "be64" => read_be64(data, offset).map(|v| Value::Int(v as i64)),
        "string" => None, // Handled separately in compare
        _ => None,
    }
}

fn read_le16(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; 2] = data.get(offset..offset + 2)?.try_into().ok()?;
    Some(u16::from_le_bytes(bytes) as u64)
}

fn read_le32(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; 4] = data.get(offset..offset + 4)?.try_into().ok()?;
    Some(u32::from_le_bytes(bytes) as u64)
}

fn read_le64(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; 8] = data.get(offset..offset + 8)?.try_into().ok()?;
    Some(u64::from_le_bytes(bytes))
}

fn read_be16(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; 2] = data.get(offset..offset + 2)?.try_into().ok()?;
    Some(u16::from_be_bytes(bytes) as u64)
}

fn read_be32(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; 4] = data.get(offset..offset + 4)?.try_into().ok()?;
    Some(u32::from_be_bytes(bytes) as u64)
}

fn read_be64(data: &[u8], offset: usize) -> Option<u64> {
    let bytes: [u8; 8] = data.get(offset..offset + 8)?.try_into().ok()?;
    Some(u64::from_be_bytes(bytes))
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
