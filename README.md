# Android device tree for the Coolpad / Yulong 3917JR (codename `gaea`)

Device tree for the 3917JR — Qualcomm SM6125 (`lito`), A/B with dynamic partitions,
stock Android 10 vendor image. This branch (`pixelos-13`) targets **PixelOS 13
(Android 13)** and boots on real hardware with SELinux enforcing.

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

**PixelOS 13 boots from the normal `boot_a` with SELinux enforcing** —
`sys.boot_completed=1`, system_server stable, verified across a reboot
(2026-11-14). The build fingerprint used for that verification was
`Coolpad/pixelos_gaea/gaea:13/TQ3C.230901.001.B1/root11141256:userdebug`.

What it took, beyond the usual A13 device-tree work:

| Area | Change |
|---|---|
| SEPolicy routing | `TARGET_USES_PREBUILT_VENDOR_SEPOLICY := true` — see below |
| APEX | `OVERRIDE_TARGET_FLATTEN_APEX := true` (flattened APEX to match the stock vendor's directory layout) |
| Boot header | `BOARD_MKBOOTIMG_ARGS += --header_version 2` (A13 bootloader rejects header v0) |
| DTB | `BOARD_PREBUILT_DTBIMAGE_DIR` pointing at a single-DTB directory |
| fstab | copied into the ramdisk as well as `/vendor/etc` (first-stage mount) |
| AVB | disabled — this device is flashed with `fastboot`, not a verified-boot chain |

### Why `TARGET_USES_PREBUILT_VENDOR_SEPOLICY`

`device/lineage/sepolicy/common/sepolicy.mk` only sets this variable automatically
when `BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE` is empty. This tree declares an ext4 vendor
partition, so the automatic path does not fire and the shared rules in
`sepolicy/common/dynamic/` get appended to `BOARD_VENDOR_SEPOLICY_DIRS` instead.
Since this device never builds or flashes a vendor image, those rules were silently
dropped — including the `vendor.lineage.health.IChargingControl` service context.
Without it, `servicemanager` returns `EX_SECURITY` for that lookup, the uncaught
exception escapes `ChargingControlController` and takes `system_server` down every
five seconds. Declaring the variable explicitly routes the shared rules into
system_ext, where they are actually loaded.

This is the one non-obvious fix in the tree. If you fork this for another
`lito` device that keeps its stock vendor, expect to need the same line.

## Build

```sh
. build/envsetup.sh
lunch pixelos_gaea-userdebug
mka bacon
```

The kernel is built in its own tree (repository above) and consumed as a prebuilt:

```sh
tools/sync-prebuilts.sh <Image> <dtbo.img>   # fills prebuilt/, git-ignored
```

Binaries never enter this repository. See `prebuilt/README.md` for which artifact
comes from where.

## Known gaps

- **Security patch level is a declaration, not an upgrade.** `ro.build.version.security_patch`
  is set to `2026-02-01` so the stock Keymaster accepts the existing `/data` blobs
  (the original blobs are bound to a higher version; without the declaration TEE
  returns `begin -62` → `upgradeKey -38` and `/data` never mounts). The code base is
  still the 2023-09 AOSP baseline. Do not read the property as evidence of patched
  vulnerabilities.
- A handful of `sysfs` reads by `system_server` are still denied under enforcing
  (USB PD extcon `name` nodes). Non-fatal — the framework takes the null branch.
- `BOARD_SEPOLICY_DIRS` is a dead variable in A13; `sepolicy/vendor/` in this tree
  is a placeholder and has no effect. Device-specific vendor-side rules would need
  `BOARD_VENDOR_SEPOLICY_DIRS`.

## License

Apache-2.0. See [`LICENSE`](LICENSE).
