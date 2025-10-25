#!/bin/bash
set -e

# Stage 07: Leak demo - learn to leak addresses to bypass ASLR
# Protections: NX=On, ASLR=On (system), PIE=Off (for simplicity), Canary=Off

echo "[*] Building stage07_leak_demo..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile with NX enabled, no PIE, no canary
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -no-pie \
    -z relro \
    server.c \
    -o ../build/stage07_leak_demo

echo "[+] Built: ../build/stage07_leak_demo"
echo "[+] Protections:"
echo "    - Canary: OFF"
echo "    - NX: ON (no execstack)"
echo "    - PIE: OFF"
echo "    - RELRO: Partial"
echo "[+] Server provides LEAK command to get libc address"
echo "[+] Learn to calculate libc base from leaked address"
echo "[+] Run with: ../build/stage07_leak_demo"
echo "[+] Test with: python3 ../solver/stage07_leak_demo.py"
echo "[+] Verify protections: checksec --file=../build/stage07_leak_demo"
