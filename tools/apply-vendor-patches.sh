#!/bin/bash
#
# 重新应用对上游仓库的本地修改。
#
# 背景：Aperture（PixelOS 默认相机）必须从 vendor/aosp 移除，否则
# STILL_IMAGE_CAMERA 会有两个 handler（Aperture + 预装的 GCam），
# 点开相机弹选择器。
#
# 为什么不在设备树里 filter-out：
#   PRODUCT_PACKAGES 里存的是 @inherit:xxx 占位符，不是实际包名。
#   在 mk 文件里用 := 过滤时继承还没展开（实测只有 10 项），静默失效；
#   用 = 延迟展开会自引用无限递归；
#   用 $(value PRODUCT_PACKAGES) 会把 @inherit: 占位符一起过滤掉，
#   product 分区直接塌成 60 MB。
#   product_config.mk 末尾有 readonly-product-vars，之后 PRODUCT_PACKAGES 只读。
#   所以只能在源头（vendor/aosp）改。
#
# 用法：repo sync 之后、构建之前跑一次。
#   device/coolpad/gaea/tools/apply-vendor-patches.sh /root/pixelos

set -euo pipefail

TOP="${1:-$(pwd)}"
MOBILE_MK="$TOP/vendor/aosp/config/common_mobile.mk"

if [ ! -f "$MOBILE_MK" ]; then
    echo "ERROR: $MOBILE_MK 不存在，先 repo sync" >&2
    exit 1
fi

if ! grep -q "^PRODUCT_PACKAGES += \\\\$" "$MOBILE_MK"; then
    echo "WARN: $MOBILE_MK 结构变了，人工检查 Aperture 是否还在" >&2
fi

# 幂等：已经移除过就跳过
if ! grep -qE '^\s+Aperture$' "$MOBILE_MK"; then
    echo "Aperture 已移除，跳过"
    exit 0
fi

python3 - "$MOBILE_MK" << 'PYEOF'
import sys

path = sys.argv[1]
s = open(path).read()

old = """# Apps
PRODUCT_PACKAGES += \\
    Aperture
"""
new = """# Apps
# Aperture 已移除：本设备用预装的 GCam（org.codeaurora.snapcam）作为唯一相机。
# 保留 Aperture 会让 STILL_IMAGE_CAMERA 有两个 handler，点开弹选择器。
# 由 device/coolpad/gaea 的 apply-vendor-patches.sh 在 repo sync 后重新应用。
"""

if old not in s:
    print("ERROR: 未找到预期片段，vendor/aosp 可能已更新，人工检查", file=sys.stderr)
    sys.exit(1)

open(path, "w").write(s.replace(old, new))
print("已移除 Aperture")
PYEOF

echo "完成。下一步：make productimage"
