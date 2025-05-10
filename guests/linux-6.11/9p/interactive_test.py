#!/usr/bin/env python3
"""
Interactive 9P test client
"""

import socket
import sys
import struct
import select
import time

def hexdump(data):
    """Print hex dump of data"""
    for i in range(0, len(data), 16):
        hex_str = ' '.join(f'{b:02x}' for b in data[i:i+16])
        ascii_str = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in data[i:i+16])
        print(f'{i:08x}  {hex_str:<48}  |{ascii_str}|')

def send_and_receive(sock, data, timeout=2.0):
    """Send data and wait for response with timeout"""
    print(f"Sending {len(data)} bytes:")
    hexdump(data)
    
    sock.send(data)
    
    # Wait for response with timeout
    ready, _, _ = select.select([sock], [], [], timeout)
    if ready:
        try:
            resp = sock.recv(4096)
            if resp:
                print(f"\nReceived {len(resp)} bytes:")
                hexdump(resp)
                return resp
            else:
                print("\nConnection closed by server")
                return None
        except Exception as e:
            print(f"\nError receiving: {e}")
            return None
    else:
        print(f"\nNo response within {timeout} seconds")
        return None

def test_version(sock):
    """Send Tversion and wait for Rversion"""
    print("\n=== Testing Tversion ===")
    
    # Build Tversion message
    msize = 8192
    version = b"9P2000"
    
    # size[4] type[1] tag[2] msize[4] version[s]
    msg = struct.pack('<BHI', 100, 0xFFFF, msize)  # type=100 (Tversion), tag=NOTAG
    msg += struct.pack('<H', len(version)) + version
    
    # Add message size
    full_msg = struct.pack('<I', len(msg) + 4) + msg
    
    return send_and_receive(sock, full_msg)

def test_attach(sock):
    """Send Tattach and wait for Rattach"""
    print("\n=== Testing Tattach ===")
    
    # Build Tattach message
    fid = 0
    afid = 0xFFFFFFFF  # NOFID
    uname = b"nobody"
    aname = b""
    
    # size[4] type[1] tag[2] fid[4] afid[4] uname[s] aname[s]
    msg = struct.pack('<BHII', 104, 0, fid, afid)  # type=104 (Tattach), tag=0
    msg += struct.pack('<H', len(uname)) + uname
    msg += struct.pack('<H', len(aname)) + aname
    
    # Add message size
    full_msg = struct.pack('<I', len(msg) + 4) + msg
    
    return send_and_receive(sock, full_msg)

def test_stat(sock):
    """Send Tstat and wait for Rstat"""
    print("\n=== Testing Tstat ===")
    
    # Build Tstat message
    fid = 0
    
    # size[4] type[1] tag[2] fid[4]
    msg = struct.pack('<BHI', 124, 1, fid)  # type=124 (Tstat), tag=1
    
    # Add message size
    full_msg = struct.pack('<I', len(msg) + 4) + msg
    
    return send_and_receive(sock, full_msg)

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <socket_path>")
        sys.exit(1)
    
    socket_path = sys.argv[1]
    
    print(f"Connecting to {socket_path}...")
    
    # Create socket
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    
    try:
        sock.connect(socket_path)
        print("Connected!")
        
        # Run tests
        if test_version(sock):
            if test_attach(sock):
                test_stat(sock)
        
    except socket.error as e:
        print(f"Socket error: {e}")
    except KeyboardInterrupt:
        print("\nInterrupted")
    finally:
        print("\nClosing connection...")
        sock.close()

if __name__ == "__main__":
    main()