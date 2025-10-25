#!/bin/bash
# Build script for task05_rotn_time_keygen

set -e  # Exit on error

echo "[*] Building task05_rotn_time_keygen (re105)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re105" ]; then
    echo "[+] Success! Binary created: build/re105"
    echo "[*] File info:"
    file build/re105
else
    echo "[-] Build failed!"
    exit 1
fi
