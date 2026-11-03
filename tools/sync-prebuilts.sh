#!/bin/bash
# 把验收集的内核工件同步到设备树 prebuilt/（二进制不入 Git）
# 用法: tools/sync-prebuilts.sh <Image> <dtbo.img>
set -euo pipefail
DEVICE_PATH="$(cd "$(dirname "$0")/.." && pwd)"
PRE="$DEVICE_PATH/prebuilt"
[ $# -eq 2 ] || { echo "usage: $0 <Image> <dtbo.img>" >&2; exit 2; }
IMG="$1"; DTBO="$2"
for f in "$IMG" "$DTBO"; do [ -f "$f" ] || { echo "missing: $f" >&2; exit 1; }; done

mkdir -p "$PRE"
cp -f "$IMG"  "$PRE/Image"
cp -f "$DTBO" "$PRE/dtbo.img"

echo "== 已同步到 $PRE"
sha256sum "$PRE/Image" "$PRE/dtbo.img"
echo -n "内核版本: "
strings "$PRE/Image" | grep -m1 "Linux version" || echo "(未找到版本串)"
echo "== 验收集要求: 与 rom-porting/A13-PORT-PLAN 中记录的 sha256 一致才算同一内核"
