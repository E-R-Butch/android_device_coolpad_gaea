#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 3917JR / gaea / lito(SM7250) —— 数值全部来自 2026-10-17 原厂系统实测。
# 标 TODO(verify) 的条目需在跑 breakfast 前逐项核（不要凭参考树猜）。
#

DEVICE_PATH := device/coolpad/gaea

# ---------------------------------------------------------------- 架构
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := kryo
TARGET_CPU_VARIANT_RUNTIME := kryo

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := kryo
TARGET_2ND_CPU_VARIANT_RUNTIME := kryo

TARGET_BOARD_PLATFORM := lito
TARGET_BOOTLOADER_BOARD_NAME := lito
# TODO(verify): 原厂 ro.boot.hardware=qcom，board name 需按 DT/bootloader 实测确认
TARGET_USES_64_BIT_BINDER := true
TARGET_SUPPORTS_64_BIT_APPS := true

# ---------------------------------------------------------------- 内核
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_CMDLINE := rcuupdate.rcu_expedited=1 rcu_nocbs=0-7 earlycon=msm_geni_serial,0x888000 console=ttyMSM0,115200,n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 cgroup.memory=nokmem,nosocket loop.max_part=7

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_CLANG_COMPILE := true
TARGET_KERNEL_SOURCE := kernel/coolpad/gaea
# TODO: 放入我们的内核树（或改 prebuilt）
TARGET_KERNEL_CONFIG := vendor/lito-perf_defconfig
# 本树已存在该 defconfig（实测）
TARGET_KERNEL_ADDITIONAL_FLAGS := HOSTCFLAGS="-fuse-ld=lld -Wno-unused-command-line-argument"

BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_INCLUDE_DTB_IN_BOOTIMG := true

# ---------------------------------------------------------------- 分区（实测）
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
# 实测（参考树 134217728 不可用）
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
# 实测（参考树 33554432 不可用）
BOARD_METADATAIMAGE_PARTITION_SIZE := 16777216
# TODO(verify): 变量名按 AOSP 核对
BOARD_USERDATAIMAGE_PARTITION_SIZE := 110225207296
# 实测
BOARD_FLASH_BLOCK_SIZE := 262144

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_USES_MKE2FS := true
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_VENDOR := vendor

ifneq ($(WITH_GMS),true)
BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := -1
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 1258291200
BOARD_SYSTEM_EXTIMAGE_EXTFS_INODE_COUNT := -1
BOARD_SYSTEM_EXTIMAGE_PARTITION_RESERVED_SIZE := 1258291200
BOARD_PRODUCTIMAGE_EXTFS_INODE_COUNT := -1
BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE := 1258291200
else
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 30720000
BOARD_SYSTEM_EXTIMAGE_PARTITION_RESERVED_SIZE := 30720000
BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE := 30720000
endif
BOARD_VENDORIMAGE_PARTITION_RESERVED_SIZE := 30720000

# ---------------------------------------------------------------- 动态分区（实测：super 内只有 system/product/vendor）
BOARD_SUPER_PARTITION_SIZE := 12884901888
# 实测 12 GiB
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
# 原厂 super 只有 system/product/vendor；A11 需要 system_ext ⇒ 重建 super 时新增该分区
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 12880707584
# BOARD_SUPER_PARTITION_SIZE - 4 MiB

# ---------------------------------------------------------------- A/B
AB_OTA_UPDATER := true
# TODO(verify): 与 vendor 的 bootctl/update_engine 版本对齐
AB_OTA_PARTITIONS += boot dtbo vbmeta system system_ext product vendor

# ---------------------------------------------------------------- qcom 平台
BOARD_USES_QCOM_HARDWARE := true
BOARD_VENDOR := coolpad
TARGET_USES_GRALLOC1 := true
TARGET_USES_GRALLOC4 := true

# ---------------------------------------------------------------- 显示/触摸（原厂节点，待实测确认）
# TARGET_TAP_TO_WAKE_NODE := "..."                            # TODO: 原厂 touchpanel 节点待查

# ---------------------------------------------------------------- SELinux
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
BOARD_PLATFORM_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public
# TODO(verify): 上面这行的变量名（BOARD_PLATFORM_SEPOLICY_DIRS）按 18.1 核对

# ---------------------------------------------------------------- AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
# TODO: 换成我们自己的 key
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1

# ---------------------------------------------------------------- 恢复
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
# TODO: 放入实测 fstab
