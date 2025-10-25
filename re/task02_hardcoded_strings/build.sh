#!/bin/bash
# Build script for task02_hardcoded_strings

set -e  # Exit on error

echo "[*] Building task02_hardcoded_strings (re102)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re102" ]; then
    echo "[+] Success! Binary created: build/re102"
    echo "[*] File info:"
    file build/re102
else
    echo "[-] Build failed!"
    exit 1
fi
