#!/bin/bash
set -e

# Stage 04: Demo without offset - direct function call
# Protections: not critical, but no-pie for easier address reading

echo "[*] Building stage04_demo_no_offset..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile with no-pie for stable addresses
gcc -Wall -Wextra -O2 \
    -no-pie \
    server.c \
    -o ../build/stage04_demo_no_offset

echo "[+] Built: ../build/stage04_demo_no_offset"
echo "[+] Binary has win() function at a fixed address"
echo "[+] Run with: ../build/stage04_demo_no_offset"
echo "[+] Test with: python3 ../solver/stage04_demo_no_offset.py"
