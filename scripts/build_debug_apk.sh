#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
OUTPUT_DIR="$ROOT_DIR/build/app/outputs/flutter-apk"
DEFAULT_APK="$OUTPUT_DIR/app-debug.apk"
NAMED_APK="$OUTPUT_DIR/小龟寻物-debug.apk"

cd "$ROOT_DIR"
"$FLUTTER_BIN" build apk --debug --target-platform android-arm64 "$@"
cp "$DEFAULT_APK" "$NAMED_APK"

printf '生成完成：%s\n' "$NAMED_APK"
