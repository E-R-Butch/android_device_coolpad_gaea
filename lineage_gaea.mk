#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from gaea device
$(call inherit-product, device/coolpad/gaea/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_gaea
PRODUCT_DEVICE := gaea
PRODUCT_BRAND := Rakuten
PRODUCT_MODEL := 3917JR
PRODUCT_MANUFACTURER := Yulong

PRODUCT_GMS_CLIENTID_BASE := android-yulong

# Device is A/B with dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true
