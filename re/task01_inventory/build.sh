#!/bin/bash
# Build script for task01_inventory

set -e  # Exit on error

echo "[*] Building task01_inventory (re101)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re101" ]; then
    echo "[+] Success! Binary created: build/re101"
    echo "[*] File info:"
    file build/re101
else
    echo "[-] Build failed!"
    exit 1
fi
