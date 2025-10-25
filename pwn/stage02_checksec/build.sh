#!/bin/bash
set -e

# Stage 02: checksec - demonstrate different binary protections
# Build multiple binaries with different protection combinations

echo "[*] Building stage02_checksec variants..."

# Create build directory if it doesn't exist
mkdir -p ../build

# Variant 1: All protections OFF
echo "[*] Building: no protections..."
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -z execstack \
    -no-pie \
    -z norelro \
    dummy.c \
    -o ../build/stage02_no_protections

# Variant 2: All protections ON (default modern gcc)
echo "[*] Building: all protections..."
gcc -Wall -Wextra -O2 \
    -fstack-protector-all \
    -D_FORTIFY_SOURCE=2 \
    -pie -fPIE \
    -z now -z relro \
    dummy.c \
    -o ../build/stage02_all_protections

# Variant 3: Only NX (most common for PWN challenges)
echo "[*] Building: only NX..."
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -no-pie \
    -z relro \
    dummy.c \
    -o ../build/stage02_only_nx

# Variant 4: NX + PIE (ASLR challenge)
echo "[*] Building: NX + PIE..."
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -pie -fPIE \
    -z relro \
    dummy.c \
    -o ../build/stage02_nx_pie

echo ""
echo "[+] Built 4 variants in ../build/"
echo "[+] Check them with: checksec --file=../build/stage02_*"
echo ""
echo "Examples:"
echo "  checksec --file=../build/stage02_no_protections"
echo "  checksec --file=../build/stage02_all_protections"
echo "  checksec --file=../build/stage02_only_nx"
echo "  checksec --file=../build/stage02_nx_pie"
