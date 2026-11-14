CUSTOM_BUILD := gaea
TOOLS_PATH_OVERRIDE := /usr/bin

BUILD_WITHOUT_VENDOR := true
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

# 内核走 prebuilt（R48 验收集：binderfs 兼容层 + rt1011 内建），二进制不入 Git
# 见 tools/sync-prebuilts.sh
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
# 源码编内核的旧配置保留备查（当前不用；A13 阶段直接用 R48 产物）
# TARGET_KERNEL_SOURCE := kernel/coolpad/gaea
# TARGET_KERNEL_CONFIG := vendor/lito-perf_defconfig
# TARGET_KERNEL_CLANG_COMPILE := true
# TARGET_KERNEL_ADDITIONAL_FLAGS := HOSTCFLAGS="-fuse-ld=lld -Wno-unused-command-line-argument"

BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
# dtb.img 由 BOARD_PREBUILT_DTBIMAGE_DIR/*.dtb 拼接生成（build/make/core/Makefile:860）
# 设备树只有单个 prebuilt/dtb/dtb，改名放入 dtbimage/ 供通配符匹配
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtbimage

# ---------------------------------------------------------------- 分区（实测）
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
# Android 13 bootloader 要求 boot header v2（含 dtb_size/dtb_addr 字段）。
# AOSP 13 的 build/make 不再读 BOARD_BOOT_HEADER_VERSION，
# header 版本只能通过 BOARD_MKBOOTIMG_ARGS 传给 mkbootimg。
# 不设时默认 0（Android 8 格式），bootloader 加载后约 16 s 退回 fastboot。
BOARD_MKBOOTIMG_ARGS += --header_version 2
# 实测（参考树 134217728 不可用）
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
# 实测（参考树 33554432 不可用）
TARGET_KERNEL_ARCH := arm64
BOARD_METADATAIMAGE_PARTITION_SIZE := 16777216
BOARD_USES_METADATA_PARTITION := true
BOARD_USERDATAIMAGE_PARTITION_SIZE := 110225207296
# 实测
BOARD_FLASH_BLOCK_SIZE := 262144

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
# DSU 单镜模式：合并 system_ext 和 product 到单一 system.img
TARGET_COPY_OUT_SYSTEM_EXT := system/system_ext
TARGET_COPY_OUT_PRODUCT := product
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE :=
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_PARTITION_SIZE := 1946632192
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_USES_MKE2FS := true
TARGET_COPY_OUT_VENDOR := vendor

# 本机不构建也不刷写 vendor 镜像，使用原厂 vendor。
# 必须显式声明，否则 device/lineage/sepolicy/common/sepolicy.mk 的自动判定
# （依赖 BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE 为空）不成立，
# 会把 dynamic/ 等规则路由进 BOARD_VENDOR_SEPOLICY_DIRS 而静默丢失。
TARGET_USES_PREBUILT_VENDOR_SEPOLICY := true

ifneq ($(WITH_GMS),true)
BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := -1
BOARD_SYSTEM_EXTIMAGE_EXTFS_INODE_COUNT := -1
BOARD_PRODUCTIMAGE_EXTFS_INODE_COUNT := -1
else
endif
BOARD_VENDORIMAGE_PARTITION_RESERVED_SIZE := 30720000

# Fixed-size target partitions: keep reserve small enough for system_a/product_a

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
AB_OTA_PARTITIONS += boot dtbo vbmeta vbmeta_system system system_ext product vendor

# ---------------------------------------------------------------- qcom 平台
BOARD_USES_QCOM_HARDWARE := true
BOARD_VENDOR := coolpad
TARGET_USES_GRALLOC4 := false
TARGET_USES_GRALLOC3 := true

# ---------------------------------------------------------------- 显示/触摸（原厂节点，待实测确认）
# TARGET_TAP_TO_WAKE_NODE := "..."                            # TODO: 原厂 touchpanel 节点待查

# ---------------------------------------------------------------- SELinux
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/system_ext
# A13 起 BOARD_PLATFORM_SEPOLICY_DIRS 已不存在：平台侧策略走 SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS

# ---------------------------------------------------------------- AVB
BOARD_AVB_ENABLE := false
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Enable chain partition for system (verified by fstab avb_keys / bootloader)
BOARD_AVB_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_SYSTEM_ROLLBACK_INDEX := 1770076800
BOARD_AVB_SYSTEM_ROLLBACK_INDEX_LOCATION := 0
BOARD_AVB_SYSTEM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256 --rollback_index 1770076800
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3159343104
# ---------------------------------------------------------------- 恢复
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
# TODO: 放入实测 fstab
TOOLS_PATH_OVERRIDE := /usr/bin

# ---------------------------------------------------------------- APEX
# 强制扁平化 APEX（目录形式），与 vendor 的 /system/apex 目录布局一致。
# 不设此项时 updatable_apex.mk 会设 ro.apex.updatable=true + TARGET_FLATTEN_APEX=false，
# 导致 apexd 去找 .apex 文件（不存在），Activated 0 packages，
# /apex/com.android.runtime 空 → linkerconfig 执行失败 → ld.config.txt 不生成
# → secilc 无法运行 → SELinux 策略编译失败 → bootloop。
OVERRIDE_TARGET_FLATTEN_APEX := true

# ---------------------------------------------------------------- vendor/aosp 配置
# BoardConfigSoong.mk 定义 PATH_OVERRIDE_SOONG（来自 TOOLS_PATH_OVERRIDE），
# 并导出 KERNEL_* 等变量给 soong。不 include 会导致：
#   error: vendor/aosp/build/soong/Android.bp:24:8: module "generated_kernel_includes":
#          cmd: unknown variable \$(PATH_OVERRIDE_SOONG)
#   soong bootstrap failed
# 之前 m systemimage 能过是因为增量构建用了缓存的 build.ninja，
# m bootimage 触发完整 soong 分析才暴露。
include vendor/aosp/config/BoardConfigCustom.mk
