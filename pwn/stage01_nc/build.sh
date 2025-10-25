#!/bin/bash
set -e

# Stage 01: nc - TCP interaction
# No specific protections needed, just a simple TCP server

echo "[*] Building stage01_nc..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Compile server (net functions are static inline in net.h)
gcc -Wall -Wextra -O2 \
    -I../common \
    server.c \
    -o ../build/stage01_nc

echo "[+] Built: ../build/stage01_nc"
echo "[+] Run with: ../build/stage01_nc"
echo "[+] Connect with: nc 127.0.0.1 7101"
