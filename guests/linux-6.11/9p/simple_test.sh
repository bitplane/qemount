#!/bin/bash
# Simple test to check 9P connection

SOCKET="/tmp/9p.sock"

echo "Testing 9P connection..."

# Try to send a simple version message
echo -ne '\x13\x00\x00\x00\x64\xff\xff\x00\x20\x00\x00\x06\x009P2000' | nc -U "$SOCKET" | hexdump -C

echo ""
echo "Connection test complete."