#!/bin/bash
set -e

# Stage 05: Demo with hint - buffer overflow with offset hint
# Protections: all OFF for beginner-friendly exploitation

echo "[*] Building stage05_demo_with_hint..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile with all protections OFF
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -z execstack \
    -no-pie \
    server.c \
    -o ../build/stage05_demo_with_hint

echo "[+] Built: ../build/stage05_demo_with_hint"
echo "[+] Protections:"
echo "    - Canary: OFF"
echo "    - NX: OFF"
echo "    - PIE: OFF"
echo "[+] Server will hint if padding is insufficient"
echo "[+] Run with: ../build/stage05_demo_with_hint"
echo "[+] Test with: python3 ../solver/stage05_demo_with_hint.py"
