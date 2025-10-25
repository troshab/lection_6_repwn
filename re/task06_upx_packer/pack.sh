#!/usr/bin/env bash
set -euo pipefail
mkdir -p build
upx -9 build/re106 -o build/re106_packed
