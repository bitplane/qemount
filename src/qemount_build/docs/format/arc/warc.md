---
title: WARC
created: 2009
detect:
  - offset: 0
    type: string
    value: "WARC/"
---

# WARC (Web ARChive)

WARC was standardised as ISO 28500 in 2009, developed by the Internet
Archive and the International Internet Preservation Consortium (IIPC).
It stores web crawl data — HTTP requests, responses, metadata, and
revisit records — in a single sequential file.

## Characteristics

- Text-based record headers (like HTTP)
- Multiple record types (request, response, metadata, revisit, etc.)
- Content-Type and Content-Length per record
- Record IDs (UUID URIs)
- Concurrent record references for request/response pairs
- Designed for long-term preservation

## Structure

```
WARC/1.0\r\n
WARC-Type: response\r\n
WARC-Date: 2024-01-15T12:00:00Z\r\n
WARC-Record-ID: <urn:uuid:...>\r\n
Content-Type: application/http;msgtype=response\r\n
Content-Length: 12345\r\n
\r\n
[record payload]
\r\n\r\n
```

## Record Types

| Type | Description |
|------|-------------|
| warcinfo | Archive metadata |
| response | HTTP response (headers + body) |
| request | HTTP request |
| metadata | Additional metadata about a record |
| revisit | Duplicate content reference |
| resource | Standalone resource |
| conversion | Format conversion of another record |
| continuation | Continuation of a segmented record |

## Usage

- Internet Archive's Wayback Machine
- National library web archives
- Common Crawl dataset
- Typically compressed with gzip (`.warc.gz`)
