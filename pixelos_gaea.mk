#
# Copyright (C) 2026 The PixelOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# ---------------------------------------------------------------- 发版裁剪
# 必须在 inherit-product 之前设置：handheld_product.mk / base_system.mk 用
# ifeq ($(CUSTOM_BUILD),) 判断是否加入 AOSP 的 Camera2、LatinIME、su。
# 本产品不用 AOSP Camera2（保留 Aperture），输入法用 LatinImeGoogle
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

# 自持签名：PixelOS 的 vendor/aosp 没有 lineage-priv 那样的 keys.mk 钩子
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/aosp-priv/keys/releasekey
PRODUCT_EXTRA_RECOVERY_KEYS += vendor/aosp-priv/keys/releasekey
TARGET_CALL_RECORDING_SUPPORTED := false

# ---------------------------------------------------------------- 发版裁剪
# Drive / Maps：11-06 因 product 空间不足删除，用户从 Play 商店自装。
# Music：AOSP 13 占位应用，无音乐库管理，用户用 Play Music 或本地播放器。
# gsi_skip_mount.cfg：独立 product 分区，不需要 skip-mount 配置。
# Camera2 / LatinIME 由文件开头的 CUSTOM_BUILD 排除，不在此列。
PRODUCT_PACKAGES := $(filter-out gsi_skip_mount.cfg Drive Maps Music,$(PRODUCT_PACKAGES))
