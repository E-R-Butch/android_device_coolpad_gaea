# Android device tree for the Coolpad / Yulong 3917JR (codename `gaea`)

LineageOS device tree for the 3917JR — Qualcomm SM6125 (`lito`), A/B with dynamic
partitions, stock vendor image from Android 10.

Every value in here was measured on the device itself (`getprop`, `blockdev`,
`lpdump`); the measurement tables live in [`FACTS-AND-MAPPING.md`](FACTS-AND-MAPPING.md),
including the places where this device differs from the usual Qualcomm reference
boards (partition sizes, `dtbo_idx`, super layout).

## Device facts

| | |
|---|---|
| Codename | `gaea` |
| Model | 3917JR (brand Rakuten, manufacturer Yulong/Coolpad) |
| Platform | `lito` (SM6125) |
| Stock release | Android 10, vendor API 29, vendor target-level 4, VNDK 29 |
| Partitions | A/B, `super` 12 GiB (`system`/`vendor`/`product` only in stock) |
| `boot_a` | 96 MiB |
| `dtbo_a` | 24 MiB, `ro.boot.dtbo_idx=13` |
| Kernel | separate tree: <https://github.com/E-R-Butch/3917JR_kernel> (`4.19.81-gaea-*`) |

## Status

- **lineage-18.1 (Android 11)**: device tree written, build not finished.
- **lineage-20 (Android 13)**: in progress, now validated against a running system —
  a LineageOS 20 GSI boots on this device with the stock Android 10 vendor, so the
  vendor compatibility question is answered. Adjustments for A13 are listed in
  `FACTS-AND-MAPPING.md` §6: `PRODUCT_SHIPPING_API_LEVEL := 29`,
  `PRODUCT_EXTRA_VNDK_VERSIONS := 29`, metadata partition, gralloc1 removal,
  `vbmeta_system` in the A/B set, and a prebuilt kernel.
- Kernel: `4.19.81-gaea-R48` — adds `binderfs` (required by Android 13's `init.rc`,
  which symlinks `/dev/binder` through `/dev/binderfs`) and builds the RT1011
  speaker codec in-tree, matching the stock kernel's `CONFIG_SND_SOC_RT1011=y`.

This tree deliberately does **not** inherit `vendor/coolpad/gaea/gaea-vendor.mk`:
the vendor partition stays the stock one, so the blobs are not part of the build
(see the comment in `device.mk`). A full flashable build would need them.

## Build

```sh
. build/envsetup.sh
lunch lineage_gaea-userdebug
mka bacon
```

The kernel is built in its own tree (repository above) and consumed as a prebuilt:

```sh
tools/sync-prebuilts.sh <Image> <dt_table> <dtbo.img>   # fills prebuilt/, git-ignored
```

Binaries never enter this repository. See `prebuilt/README.md` for which artifact
comes from where, and `BoardConfig.mk` for the `TARGET_KERNEL_SOURCE` alternative if
the QTI `dt_table` cannot be consumed as a DTB image directory.

## Known gaps

`BoardConfig.mk` carries `TODO(verify)` markers for the items that were not yet
confirmed on hardware — `TARGET_BOOTLOADER_BOARD_NAME`, AVB keys, and the touchpanel
wake node. Please keep them until they are measured, rather than replacing them with
guesses.

Open questions that need the LineageOS 20 sources to settle are tracked at the end of
`FACTS-AND-MAPPING.md` §6 (sepolicy variable names, whether `BOARD_PREBUILT_DTBIMAGE_DIR`
accepts a single QTI `dt_table` blob, and whether `PRODUCT_EXTRA_VNDK_VERSIONS := 29`
is enough for the Android 10 vendor).

## License

Apache-2.0. See [`LICENSE`](LICENSE).
