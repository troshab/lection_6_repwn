#!/bin/bash
set -e

# Stage 08: ret2libc - full ret2libc exploitation with NX + ASLR
# Protections: NX=On, ASLR=On (system), PIE=Off, Canary=Off
# Uses dlsym for real libc address leak

echo "[*] Building stage08_ret2libc..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile with NX enabled, no PIE, no canary, link with dl for dlsym
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -no-pie \
    -z relro \
    server.c \
    -ldl \
    -o ../build/stage08_ret2libc

echo "[+] Built: ../build/stage08_ret2libc"
echo "[+] Protections:"
echo "    - Canary: OFF"
echo "    - NX: ON (no shellcode in stack)"
echo "    - PIE: OFF"
echo "    - RELRO: Partial"
echo "    - ASLR: ON (system-level)"
echo "[+] Full ret2libc challenge:"
echo "    1. LEAK command reveals libc address"
echo "    2. Calculate libc base"
echo "    3. Build ROP chain for system('/bin/sh') or ORW"
echo "[+] Run with: ../build/stage08_ret2libc"
echo "[+] Test with: python3 ../solver/stage08_ret2libc.py"
echo "[+] Verify protections: checksec --file=../build/stage08_ret2libc"
echo ""
echo "[*] Don't forget to extract libc for solver:"
echo "    ./scripts/extract_libc.sh stage08"
