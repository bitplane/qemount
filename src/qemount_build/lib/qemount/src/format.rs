//! Format rules loaded from a compiled catalogue file.

use serde::Deserialize;
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::fs;
use std::io;
use std::path::Path;
use std::sync::OnceLock;

#[derive(Debug, Deserialize)]
struct RawFormatDb {
    #[serde(rename = "version")]
    _version: u32,
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
        #[serde(rename = "name")]
        _name: Option<String>,
        #[serde(rename = "then")]
        then_rules: Option<Vec<Rule>>,
        length: Option<u32>,
        algorithm: Option<String>,
        key: Option<String>,
    },
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Value {
    Int(i64),
    UInt(u64),
    Bytes(Vec<i64>),
    String(String),
}

/// Format database with static CStr names for C API
pub struct FormatDb {
    pub formats: Vec<(&'static CStr, Detect)>,
}

pub static FORMATS: OnceLock<FormatDb> = OnceLock::new();

impl FormatDb {
    fn from_slice(data: &[u8]) -> io::Result<Self> {
        let raw: RawFormatDb = rmp_serde::from_slice(data)
            .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;

        let formats = raw
            .formats
            .into_iter()
            .map(|(name, detect)| {
                let cstr = CString::new(name)
                    .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
                let leaked: &'static CStr = Box::leak(cstr.into_boxed_c_str());
                Ok((leaked, detect))
            })
            .collect::<io::Result<Vec<_>>>()?;

        Ok(Self { formats })
    }

    fn load(path: &Path) -> io::Result<Self> {
        Self::from_slice(&fs::read(path)?)
    }
}

pub fn load(path: &Path) -> io::Result<()> {
    if FORMATS.get().is_some() {
        return Ok(());
    }

    let formats = FormatDb::load(path)?;
    let _ = FORMATS.set(formats);
    Ok(())
}

#[cfg(test)]
pub fn init_test_formats() {
    FORMATS.get_or_init(|| FormatDb {
        formats: vec![
            test_format("disk/atr", &[0x96, 0x02]),
            test_format("disk/2img", b"2IMG"),
            test_format("disk/scl", b"SINCLAIR"),
        ],
    });
}

#[cfg(test)]
fn test_format(name: &str, value: &[u8]) -> (&'static CStr, Detect) {
    let name = Box::leak(CString::new(name).unwrap().into_boxed_c_str());
    (
        name,
        Detect::All {
            all: vec![Rule::Leaf {
                offset: 0,
                typ: "string".into(),
                value: Some(Value::Bytes(
                    value.iter().map(|byte| i64::from(*byte)).collect(),
                )),
                op: None,
                mask: None,
                _name: None,
                then_rules: None,
                length: None,
                algorithm: None,
                key: None,
            }],
        },
    )
}
