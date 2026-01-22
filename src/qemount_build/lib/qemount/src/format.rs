//! Format rules loaded from embedded format.bin

use serde::Deserialize;
use std::collections::HashMap;
use std::ffi::CStr;
use std::sync::LazyLock;

const FORMAT_BIN: &[u8] = include_bytes!(env!("QEMOUNT_FORMAT_BIN"));

#[derive(Debug, Deserialize)]
struct RawFormatDb {
    version: u32,
    formats: HashMap<String, Detect>,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Detect {
    All { all: Vec<Rule> },
    Any { any: Vec<Rule> },
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Rule {
    Any { any: Vec<Rule> },
    All { all: Vec<Rule> },
    Leaf {
        offset: i64,
        #[serde(rename = "type")]
        typ: String,
        value: Option<Value>,
        op: Option<String>,
        mask: Option<u64>,
        name: Option<String>,
        #[serde(rename = "then")]
        then_rules: Option<Vec<Rule>>,
        length: Option<u32>,
    },
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Value {
    Int(i64),
    Bytes(Vec<i64>),
    String(String),
}

/// Format database with static CStr names for C API
pub struct FormatDb {
    pub formats: Vec<(&'static CStr, Detect)>,
}

pub static FORMATS: LazyLock<FormatDb> = LazyLock::new(|| {
    let raw: RawFormatDb = rmp_serde::from_slice(FORMAT_BIN)
        .expect("embedded format.bin is valid");

    let formats = raw.formats.into_iter().map(|(name, detect)| {
        // Create null-terminated string and leak it for static lifetime
        let cstr = std::ffi::CString::new(name).unwrap();
        let leaked: &'static CStr = Box::leak(cstr.into_boxed_c_str());
        (leaked, detect)
    }).collect();

    FormatDb { formats }
});
