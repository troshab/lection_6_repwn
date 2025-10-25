#!/bin/bash
# Build script for task06_upx_packer

set -e  # Exit on error

echo "[*] Building task06_upx_packer (re106)..."
echo "[*] Cleaning previous build..."
make clean

echo "[*] Compiling binary..."
make

if [ -f "build/re106" ]; then
    echo "[+] Success! Binary created: build/re106"
    echo "[*] File info:"
    file build/re106

    # Optional: Pack with UPX
    if command -v upx &> /dev/null; then
        echo ""
        echo "[*] UPX is available. Pack binary? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "[*] Packing with UPX..."
            ./pack.sh
            echo "[+] Packed binary created: build/re106_packed"
        fi
    else
        echo "[!] UPX not found. Install UPX to pack the binary."
        echo "[i] Run './pack.sh' manually after installing UPX"
    fi
else
    echo "[-] Build failed!"
    exit 1
fi
