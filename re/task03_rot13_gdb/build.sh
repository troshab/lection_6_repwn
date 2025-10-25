#!/bin/bash
# Build script for task03_rot13_gdb

set -e  # Exit on error

echo "[*] Building task03_rot13_gdb (re103)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re103" ]; then
    echo "[+] Success! Binary created: build/re103"
    echo "[*] File info:"
    file build/re103
else
    echo "[-] Build failed!"
    exit 1
fi
