#!/bin/bash
  set -e
  for dir in re/task{01..07}_* pwn/stage{01..08}_*; do
    if [ -f "$dir/build.sh" ]; then
      echo "Building $dir..."
      (cd "$dir" && bash build.sh)
    fi
  done
  echo "✓ All builds completed successfully!"
