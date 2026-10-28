#!/usr/bin/env bash
# 把已验收的内核工件同步进 prebuilt/（二进制不入 Git）
# 用法: tools/sync-prebuilts.sh <Image> <dt_table> <dtbo.img>
set -euo pipefail
[ $# -eq 3 ] || { echo "usage: $0 <Image> <dt_table> <dtbo.img>" >&2; exit 2; }
IMG=$1; DTB=$2; DTBO=$3
DIR=$(cd "$(dirname "$0")/.." && pwd)/prebuilt
mkdir -p "$DIR/dtb"
for f in "$IMG" "$DTB" "$DTBO"; do [ -f "$f" ] || { echo "missing: $f" >&2; exit 1; }; done
cp -f "$IMG"  "$DIR/Image"
cp -f "$DTB"  "$DIR/dtb/dtb"
cp -f "$DTBO" "$DIR/dtbo.img"
echo "== prebuilt 就绪"
( cd "$DIR" && sha256sum Image dtb/dtb dtbo.img )
strings "$DIR/Image" | grep -m1 "Linux version" || true
