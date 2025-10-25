#!/usr/bin/env bash
set -euo pipefail
stage="${1:-stage08}"
cid="$(docker compose ps -q ${stage})"
if [ -z "$cid" ]; then
  echo "container for $stage not running, starting..."
  docker compose up -d $stage
  cid="$(docker compose ps -q ${stage})"
fi
mkdir -p extracted
docker cp "$cid":/app/lib/libc.so.6 extracted/libc.so.6
docker cp "$cid":/app/lib/ld-linux-x86-64.so.2 extracted/ld-linux-x86-64.so.2
echo "extracted/libc.so.6 and ld-linux-x86-64.so.2 ready"
