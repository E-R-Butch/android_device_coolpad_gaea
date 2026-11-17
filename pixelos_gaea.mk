#
# Copyright (C) 2026 The PixelOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# ---------------------------------------------------------------- 发版裁剪
# 必须在 inherit-product 之前设置：handheld_product.mk / base_system.mk 用
# ifeq ($(CUSTOM_BUILD),) 判断是否加入 AOSP 的 Camera2、LatinIME、su。
# 本产品不用 AOSP Camera2 也不用 Aperture（系统只留 GCam），输入法用 LatinImeGoogle
# （包名同为 com.android.inputmethod.latin），故置为非空跳过这批 AOSP 包。
CUSTOM_BUILD := gaea

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Separate product image; do not install the skip-mount config
GAEA_SEPARATE_PRODUCT := true

# Inherit from gaea device
$(call inherit-product, device/coolpad/gaea/device.mk)

# Inherit PixelOS common stuff.
$(call inherit-product, vendor/aosp/config/common_full_phone.mk)

PRODUCT_NAME := pixelos_gaea
PRODUCT_DEVICE := gaea
PRODUCT_BRAND := Coolpad
PRODUCT_MODEL := Coolpad 3917JR
PRODUCT_MANUFACTURER := Coolpad

PRODUCT_GMS_CLIENTID_BASE := android-google

# Device is A/B with dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true

# vendor 停在 API 29 / FCM 4 ⇒ 出货 API 必须照实测值写，不是目标版本号
PRODUCT_SHIPPING_API_LEVEL := 29
# 旧 vendor 需要 29 版 VNDK 快照
PRODUCT_EXTRA_VNDK_VERSIONS := 29

PRODUCT_PACKAGES += \
    com.android.vndk.v29

# Bringup settings

# eSIM LPA (OpenEUICC)
PRODUCT_PACKAGES += \
    OpenEUICC \
    privapp_whitelist_im.angry.openeuicc.xml

# FOD Hardware Bridge
PRODUCT_PACKAGES += \
    gaea_fod_bridge

# 预装器（平台签名 priv-app，开机把 /system/preinstall/*.apk.bin 装进 /data/app）
PRODUCT_PACKAGES += \
    GaeaPreinstaller \
    privapp_whitelist_com.gaea.preinstaller.xml

# 自持签名：PixelOS 的 vendor/aosp 没有 lineage-priv 那样的 keys.mk 钩子
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/aosp-priv/keys/releasekey
PRODUCT_EXTRA_RECOVERY_KEYS += vendor/aosp-priv/keys/releasekey
TARGET_CALL_RECORDING_SUPPORTED := false

# ---------------------------------------------------------------- 预装 App
#
# GCam（BSG MGC 9.4.103 V41 snap）—— 走"预置包 + 首次启动安装"路线。
#
# 为什么不放 /system/app：
#   GCam 被 PairIP 加固，libgcastartup.so 需要 execmod（自修改内存）。
#   AOSP neverallow 规定 system_file 类型禁止 execmod：
#     neverallow * { file_type -apk_data_file -app_data_file -asec_public_file }:file execmod;
#   实测放 /system/app 必崩：
#     avc: denied { execmod } for path="/system/app/GCam/lib/arm64/libgcastartup.so"
#     tcontext=u:object_r:system_file:s0
#   放 /data/app 时 so 标签是 apk_data_file，execmod 放行，正常运行。
#
# 方案（华为 /system/delapp、小米 /system/preinstall 同款）：
#   APK 原样放 /system/preinstall/，由 GaeaPreinstaller（平台签名 priv-app）
#   在 BOOT_COMPLETED 时用 PackageInstaller API 装进 /data/app。
#   这样 so 落在 /data/app/.../lib/arm64/（apk_data_file），PairIP 通过，用户还能卸载。
#   出厂恢复后 system 里的 APK 还在，会重新安装。
#
# 为什么不用 init service 调 pm install：
#   1. init 域不能执行 /system/bin/sh（init.te 只有 vendor_shell_exec），service 静默失败
#   2. 自建域跑 cmd package 要补一整条 SELinux 权限链，补不完
#   3. 借 shell 域（seclabel u:r:shell:s0）能跑通，但等于给开机 root 脚本全开权限，不能发版
#   priv-app 域自带 app_api_service find，package_service 正好带这个属性，
#   INSTALL_PACKAGES 是 signature|privileged 自动获得，零新增 SELinux 规则。
#
# 文件名用 .apk.bin 而非 .apk：build/make/core/Makefile:29 的
# check-product-copy-files 用 $(filter %.apk,...) 拦 APK，改后缀绕过。
# PackageInstaller 不依赖后缀，getPackageArchiveInfo 直接按 zip 解析。
PRODUCT_COPY_FILES += \
    device/coolpad/gaea/prebuilt-apps/GCam/GCam.apk:$(TARGET_COPY_OUT_SYSTEM)/preinstall/GCam.apk.bin
# KernelSU-Next 管理器：内核通过扫 /data/app/*/base.apk 的 magic 识别 manager，
# 官方明确不支持装进 /system/app 或 /system/priv-app（容易被检测），
# 只能开机后经 PackageInstaller 装进 /data/app，和 GCam 走同一条路。
PRODUCT_COPY_FILES += \
    device/coolpad/gaea/prebuilt-apps/KernelSU/KernelSU_Next.apk.bin:$(TARGET_COPY_OUT_SYSTEM)/preinstall/KernelSU_Next.apk.bin
# /system/bin/su —— KernelSU 的 sucompat 只认这个路径。
#
# 为什么需要这个文件：
#   KSU 的 su 不是真二进制，是内核 hook 拦截 execve("/system/bin/su") 后
#   重定向到 /data/adb/ksud。但 shell 执行 su 前会先 access()/stat() 检查，
#   文件不存在就直接报 "inaccessible or not found"，execve 根本不会被调用，
#   hook 也就没机会触发。所以必须放一个真实文件当"靶子"。
#
# 为什么用 AOSP 的 su 而不是自己写：
#   AOSP system/extras/su 是标准实现，编出来 11 KB。它本身在 user build 里
#   提不了权（没有 setuid），但 KSU 在 execve 阶段就把它劫持走了，
#   根本走不到 AOSP 的逻辑，所以内容无所谓，只要是个可执行 ELF。
#
# 为什么不直接 PRODUCT_PACKAGES += su：
#   system/extras/su/Android.bp 里写死 install_in_xbin: true，
#   soong 的 installer.go:80 硬编码 dir = "xbin"，装到 /system/xbin/su，
#   而内核 hook 的是 /system/bin/su，对不上。
PRODUCT_COPY_FILES += \
    device/coolpad/gaea/prebuilt-bin/su:$(TARGET_COPY_OUT_SYSTEM)/bin/su
# ---------------------------------------------------------------- 发版裁剪
#
# 裁剪项：
#   gsi_skip_mount.cfg : 独立 product 分区，不需要 skip-mount 配置
#   Drive / Maps       : 11-06 因 product 空间不足删除，用户从 Play 商店自装
#   Music              : AOSP 13 占位应用，无音乐库管理，用户用 Play Music 或本地播放器
#
# 注意：这里只能裁设备自己加的包。Aperture 来自 vendor/aosp/config/common_mobile.mk，
# 在 mk 层 filter-out 不掉——PRODUCT_PACKAGES 里存的是 @inherit: 占位符
# （build/make/core/node_fns.mk:109），且 product_config.mk 末尾有
# readonly-product-vars 把变量锁成只读。Aperture 只能从 vendor 源头删，
# 见 tools/apply-vendor-patches.sh。
PRODUCT_PACKAGES := $(filter-out gsi_skip_mount.cfg Drive Maps Music,$(PRODUCT_PACKAGES))
