#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

symbols_dir="build/symbols"
mkdir -p "$symbols_dir"

case "${1:-aab}" in
  apk)
    flutter build apk \
      --release \
      --target-platform android-arm64 \
      --obfuscate \
      --split-debug-info="$symbols_dir"
    ;;
  aab)
    flutter build appbundle \
      --release \
      --obfuscate \
      --split-debug-info="$symbols_dir"
    ;;
  *)
    echo "Usage: $0 [aab|apk]" >&2
    exit 64
    ;;
esac

echo "Release symbols: $project_root/$symbols_dir"
