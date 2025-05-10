#!/usr/bin/env python3
"""
Simple host-side client to connect to the 9P server running in QEMU.
This connects to the Unix socket and can be used to test the connection.
"""

import socket
import sys
import struct
import time

def connect_to_9p_server(socket_path):
    """Connect to the 9P server via Unix socket"""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    
    # Wait for socket to be available
    for i in range(10):
        try:
            sock.connect(socket_path)
            print(f"Connected to {socket_path}")
            return sock
        except socket.error:
            print(f"Waiting for socket... attempt {i+1}")
            time.sleep(1)
    
    raise Exception(f"Failed to connect to {socket_path}")

def send_9p_version(sock):
    """Send a 9P version message"""
    # 9P2000 version string
    version = b"9P2000"
    
    # Build Tversion message (type=100)
    msg_type = 100  # Tversion
    tag = 0xFFFF    # NOTAG
    msize = 8192    # max message size
    
    # Pack the message: size[4] type[1] tag[2] msize[4] version[s]
    version_len = len(version)
    msg_body = struct.pack("<BHI", msg_type, tag, msize) + struct.pack("<H", version_len) + version
    msg_size = len(msg_body) + 4
    msg = struct.pack("<I", msg_size) + msg_body
    
    print(f"Sending Tversion: msize={msize}, version={version}")
    sock.send(msg)
    
    # Read response
    size_data = sock.recv(4)
    if len(size_data) < 4:
        print("Failed to read response size")
        return
    
    size = struct.unpack("<I", size_data)[0]
    print(f"Response size: {size}")
    
    # Read the rest of the response
    response = sock.recv(size - 4)
    if len(response) < 1:
        print("Failed to read response")
        return
    
    resp_type = response[0]
    print(f"Response type: {resp_type} (Rversion={101})")
    
    if resp_type == 101:  # Rversion
        # Parse Rversion response
        _, resp_tag, resp_msize = struct.unpack("<BHI", response[:7])
        version_data = response[7:]
        version_len = struct.unpack("<H", version_data[:2])[0]
        version_str = version_data[2:2+version_len].decode('utf-8')
        
        print(f"Rversion: msize={resp_msize}, version='{version_str}'")
    else:
        print(f"Unexpected response type: {resp_type}")

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <socket_path>")
        sys.exit(1)
    
    socket_path = sys.argv[1]
    
    try:
        sock = connect_to_9p_server(socket_path)
        send_9p_version(sock)
        sock.close()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()