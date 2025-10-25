#!/bin/bash
# Build script for task04_rotn_strlen_ghidra

set -e  # Exit on error

echo "[*] Building task04_rotn_strlen_ghidra (re104)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re104" ]; then
    echo "[+] Success! Binary created: build/re104"
    echo "[*] File info:"
    file build/re104
else
    echo "[-] Build failed!"
    exit 1
fi
