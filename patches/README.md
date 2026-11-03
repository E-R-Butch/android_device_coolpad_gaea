# AOSP / LineageOS 20 Framework Patches for Legacy 4.19 Vendor Bringup

针对 Coolpad 3917JR (gaea, SM7250 / lito) 在 Android 10 (API 29) 原厂内核 4.19.113 底包上点亮 Android 13 (LineageOS 20) 所需的平台层补丁。

## 补丁清单

### 1. `system_core_cross_version_fix.patch`
- **`init/service.cpp`**:
  4.19 原厂内核缺少 Android 11+ 的 `cgroupv2` uid freezer 特性，`createProcessGroup()` 必败。
  修改为失败时打印 ERROR 日志并继续派生服务，避免 `surfaceflinger`、`zygote`、`vold` 被拦截。
- **`init/property_service.cpp`**:
  拦截 vendor 覆盖 `ro.apex.updatable=false`。4.19 内核对压缩 APEX 的 loopback 读写有内核级缺陷，必须强制保持 false。
- **`init/selinux.cpp`**:
  强制 Permissive 模式作为诊断探针。
- **`rootdir/init.rc`**:
  引入 `init.early_gadget.rc`，并移除调试阶段导致死循环的 `start console`。

### 2. `system_bpf_legacy_kernel.patch`
- **`bpfloader/BpfLoader.cpp`**:
  4.19 旧内核未完整 backport A13 的 eBPF 校验器。
  BPF 程序校验失败时优雅降级：置 `bpf.progs_loaded=1` 并返回 0，杜绝 `sleep(20); return 2;`。
- **`bpfloader/bpfloader.rc`**:
  移除 `reboot_on_failure reboot,bpfloader-failed` 急停规则。

### 3. `system_apex_no_reboot_on_failure.patch`
- **`apexd/apexd.rc`**:
  移除 `apexd` 与 `apexd-bootstrap` 启动失败时强行重启回 Bootloader 的急停规则。
