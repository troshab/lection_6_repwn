#!/bin/bash
set -e

# Stage 03: pwntools - automation with pwntools
# Same TCP server as stage01, but for pwntools demonstration

echo "[*] Building stage03_pwntools..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile server (same as stage01, net functions are static inline in net.h)
gcc -Wall -Wextra -O2 \
    -I../common \
    server.c \
    -o ../build/stage03_pwntools

echo "[+] Built: ../build/stage03_pwntools"
echo "[+] Run with: ../build/stage03_pwntools"
echo "[+] Test with: python3 ../solver/stage03_pwntools.py"
