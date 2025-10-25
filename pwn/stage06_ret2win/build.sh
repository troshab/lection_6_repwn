#!/bin/bash
set -e

# Stage 06: ret2win - classic buffer overflow to win() function
# Protections: ALL OFF (NX=Off, PIE=Off, Canary=Off, RELRO=Off)

echo "[*] Building stage06_ret2win..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile with all protections OFF including RELRO
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -z execstack \
    -no-pie \
    -z norelro \
    server.c \
    -o ../build/stage06_ret2win

echo "[+] Built: ../build/stage06_ret2win"
echo "[+] Protections:"
echo "    - Canary: OFF"
echo "    - NX: OFF (execstack enabled)"
echo "    - PIE: OFF"
echo "    - RELRO: OFF"
echo "[+] Classic ret2win challenge - overflow to win() function"
echo "[+] Run with: ../build/stage06_ret2win"
echo "[+] Test with: python3 ../solver/stage06_ret2win.py"
echo "[+] Verify protections: checksec --file=../build/stage06_ret2win"
