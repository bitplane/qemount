---
title: shar
created: 1982
related:
  - format/arc/tar
---

# shar (Shell Archive)

shar is a Unix shell archive format dating from around 1982. A shar file
is a shell script that, when executed, recreates the archived files using
echo, cat, and sed commands. It was used to distribute source code via
Usenet and email before MIME attachments existed.

## Characteristics

- Plain text (7-bit ASCII safe)
- Self-extracting via any Bourne shell
- No compression
- No binary file support (without uuencode)
- Security risk — executes arbitrary shell commands
- Replaced by tar+gzip and MIME attachments

## Detection

No binary magic. Text-based identification via the string
`# This is a shell archive` near the start of the file. Some variants
begin with `#!/bin/sh` or start with `:` (null command).

## Structure

A typical shar file:

```sh
#!/bin/sh
# This is a shell archive
# Created by shar on 1993-03-15
echo x - extracting filename.c
sed 's/^X//' > filename.c << 'SHAR_EOF'
X#include <stdio.h>
Xint main() { return 0; }
SHAR_EOF
```

Each line of file content is prefixed with `X` to prevent shell
interpretation of special characters.

## File Extension

`.shar`, `.sh`
