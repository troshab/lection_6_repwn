#!/bin/bash
# Build script for task07_hidden_http_strace

set -e  # Exit on error

echo "[*] Building task07_hidden_http_strace (re107)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re107" ]; then
    echo "[+] Success! Binary created: build/re107"
    echo "[*] File info:"
    file build/re107
else
    echo "[-] Build failed!"
    exit 1
fi
