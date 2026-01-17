---
title: Format detection rules
provides:
  - lib/format.bin
---

# Format detection rules

Compiles detection rules from the catalogue into a msgpack binary
for consumption by the Rust detection library.

Reads `format/*` paths from `catalogue.json` and extracts their
`detect:` metadata into a normalized structure.

## Detection Schema

Detection rules are defined in format documentation frontmatter under
`docs/format/`. The path becomes the format identifier (e.g.,
`docs/format/fs/ext4.md` → `fs/ext4`).

### Basic Rule

```yaml
detect:
  - offset: 0x438      # Byte offset into file
    type: le16         # Data type to read
    value: 0xef53      # Expected value
    name: ext_magic    # Optional identifier
```

### Rule Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `offset` | int | 0 | Byte offset (negative = from end) |
| `type` | string | required | Data type (see below) |
| `value` | int/string | required | Expected value |
| `op` | string | `=` | Comparison operator |
| `mask` | int | none | Bitmask applied before comparison |
| `name` | string | none | Rule identifier for extraction |
| `then` | list | none | Nested rules (all must match) |

### Data Types

| Type | Size | Description |
|------|------|-------------|
| `byte` | 1 | Unsigned byte |
| `le16` | 2 | Little-endian 16-bit |
| `be16` | 2 | Big-endian 16-bit |
| `le32` | 4 | Little-endian 32-bit |
| `be32` | 4 | Big-endian 32-bit |
| `le64` | 8 | Little-endian 64-bit |
| `be64` | 8 | Big-endian 64-bit |
| `string` | varies | Byte string (exact match) |

### Comparison Operators

| Op | Description |
|----|-------------|
| `=` | Equal (default) |
| `&` | Bitwise AND equals value |
| `^` | Bitwise XOR equals value |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

### Alternatives (any match)

```yaml
detect:
  any:
    - offset: 0
      type: string
      value: "070701"
      name: newc
    - offset: 0
      type: le16
      value: 0x71c7
      name: binary_le
```

### Nested Rules (all must match)

```yaml
detect:
  - offset: 0x438
    type: le16
    value: 0xef53
    then:
      - offset: 0x45c
        type: le32
        mask: 0x4
        op: "&"
        value: 0x4
      - offset: 0x460
        type: le32
        op: ">="
        value: 0x40
```

### Bitmask Example

Check if bit 2 is set at offset 0x45c:

```yaml
- offset: 0x45c
  type: le32
  mask: 0x4
  op: "&"
  value: 0x4
```

## Output Format

The compiled `format.bin` is msgpack with structure:

```python
{
    "version": 1,
    "formats": {
        "fs/ext4": {"all": [...]},
        "arc/gzip": {"all": [...]},
        "arc/cpio": {"any": [...]},
    }
}
```

Each format maps to either `{"all": rules}` or `{"any": rules}`,
where rules are normalized with defaults applied.
