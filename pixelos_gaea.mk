#
# Copyright (C) 2026 The PixelOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

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

# Separate product image: do not skip /product at first-stage mount
PRODUCT_PACKAGES := $(filter-out gsi_skip_mount.cfg Drive Maps DevicePersonalizationPrebuiltPixel2020,$(PRODUCT_PACKAGES))

# 自持签名：PixelOS 的 vendor/aosp 没有 lineage-priv 那样的 keys.mk 钩子
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/aosp-priv/keys/releasekey
PRODUCT_EXTRA_RECOVERY_KEYS += vendor/aosp-priv/keys/releasekey
TARGET_CALL_RECORDING_SUPPORTED := false
