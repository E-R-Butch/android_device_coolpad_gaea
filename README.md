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
- **lineage-20 (Android 13)**: work in progress. The stock vendor stays untouched;
  the only kernel requirement found so far is a `binderfs`-compatible mount point,
  since Android 13's `init.rc` symlinks `/dev/binder` through `/dev/binderfs`.

This tree deliberately does **not** inherit `vendor/coolpad/gaea/gaea-vendor.mk`:
the vendor partition stays the stock one, so the blobs are not part of the build
(see the comment in `device.mk`). A full flashable build would need them.

## Build

```sh
. build/envsetup.sh
lunch lineage_gaea-userdebug
mka bacon
```

The kernel is built from the separate repository above; point `TARGET_KERNEL_SOURCE`
/ `TARGET_KERNEL_CONFIG` at it, or prebuild `Image` and drop it in.

## Known gaps

`BoardConfig.mk` carries `TODO(verify)` markers for the items that were not yet
confirmed on hardware — `TARGET_BOOTLOADER_BOARD_NAME`, the platform sepolicy
directory variable name, AVB keys, and the touchpanel wake node. Please keep them
until they are measured, rather than replacing them with guesses.

## License

Apache-2.0. See [`LICENSE`](LICENSE).
