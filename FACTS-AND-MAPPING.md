# gaea 设备树：实测事实与对照表

> 状态：**事实采集完成，文件编写进行中**。所有数值均为 2026-10-17 在**原厂系统**上 `getprop` / `blockdev` 实测。

## 一、设备身份（实测）

| 属性 | 值 | 用途 |
|---|---|---|
| `ro.board.platform` | **lito** | `TARGET_BOARD_PLATFORM` ✓ |
| `ro.boot.hardware` / `ro.hardware` | `qcom` | cmdline / 权限 |
| `ro.build.product` / `ro.product.device` / `ro.product.name` | **gaea** | 设备代号 ✓ |
| `ro.product.brand` | `Rakuten` | `PRODUCT_BRAND` |
| `ro.product.manufacturer` | `Yulong`（宇龙/酷派） | `PRODUCT_MANUFACTURER` |
| `ro.product.model` | `3917JR` | `PRODUCT_MODEL` |
| `ro.product.first_api_level` | **29**（Android 10） | 与 vendor FCM 4 一致 ✓ |
| `ro.boot.dtbo_idx` | **13** | 启动用 overlay 条目 ✓ |
| `ro.boot.dynamic_partitions` | `true` | super 动态分区 ✓ |
| `ro.boot.slot_suffix` | `_a` | A/B ✓ |
| `ro.boot.verifiedbootstate` | `green` | 未解锁态基线 |

## 二、分区（实测，`blockdev --getsize64`）

| 分区 | 大小 (bytes) | 备注 |
|---|---|---|
| `boot_a` | 100663296（96 MiB） | 参考树是 134217728 ✗ 必须用我们的 ✓ |
| `dtbo_a` | 25165824（24 MiB） | 参考树 33554432 ✗ |
| `vbmeta_a` | 65536 | |
| **`super`** | **12884901888（12 GiB）** | 参考树 9126805504 ✗ 必须用我们的 ✓ |
| `userdata` | 110225207296（~102.7 GiB） | |
| `metadata` | 16777216（16 MiB） | `BOARD_USES_METADATA_PARTITION := true` ✓ |

分区表是标准 Qualcomm A/B（`sda/sdd/sde/sdf` 多 LUN）：`boot_a=sde11`、`dtbo_a=sde17`、`vbmeta_a`、`super` 在 `sde` 上的动态分区组。

## 三、cmdline（实测，原厂）

```
rcupdate.rcu_expedited=1 rcu_nocbs=0-7 earlycon=msm_geni_serial,0x888000 console=ttyMSM0,115200,n8
androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1
video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1
androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 cgroup.memory=nokmem,nosocket loop.max_part=7 buildvariant=u
```

对照参考树（`sm7250-common/BoardConfigCommon.mk`）的 cmdline：共同项一致 ✓；差异项：我们有 `earlycon=`/`video=vfb…`/`buildvariant=u`，参考有 `reboot=panic_warm`/`androidboot.init_fatal_reboot_target=recovery`。**以实测为准，参考项可按需补**。

## 四、参考树（已取到容器 `/root/ref/`）

`LineageOS/android_device_xiaomi_sm7250-common@lineage-18.1` ✓（1 MB，结构：`libhidl/ bluetooth/ rootdir/ permissions/ lights/ vibrator/ sepolicy/{public,vendor,private}/ overlay/ overlay-lineage/` + `Android.mk BoardConfigCommon.mk lito.mk properties.mk`）。

**可直接借用的**：架构/CPU 变体、`TARGET_USES_GRALLOC1|4`、`BOARD_KERNEL_SEPARATED_DTBO`、`BOARD_INCLUDE_DTB_IN_BOOTIMG`、AVB 参数形状、sepolicy 目录布局、overlay 布局。
**必须换成我们数值的**：分区大小（boot/dtbo/super/userdata ✓ 见上表）、`TARGET_KERNEL_SOURCE`（`kernel/coolpad/gaea`）、kernel config（本树有 `vendor/lito-perf_defconfig` ✓）、cmdline（用实测 ✓）。
**不能抄的**：Xiaomi 的 FOD SOONG_CONFIG（`XIAOMI_LITO_FOD`）、其 overlay/sepolicy 的具体条目、其 super 分组名。

## 五、待办（下一步）

- [ ] 从参考树逐项核对 `BOARD_USES_DYNAMIC_PARTITIONS` / `BOARD_QTI_DYNAMIC_PARTITIONS_SIZE` / `AB_OTA_PARTITIONS` 的确切变量名与取值（**不猜**，读文件）
- [ ] `super` 组内实际分区清单（`adb shell ls /dev/block/mapper/` 实测）
- [ ] `vendor/coolpad/gaea` blobs 抽取（脚本 + sha256 清单）
- [ ] VINTF：复用 `rom-porting/evidence/` 的 8 个 fragment 合并结果
- [ ] overlays（`frameworks/base` 与 `packages/apps/Settings` 的最小集）
- [ ] sepolicy：先最小集（HAL 相关），按开机日志迭代
- [ ] `BoardConfig.mk` / `device.mk` 定稿后跑 `breakfast gaea` 验证被识别
