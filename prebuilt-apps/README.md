# prebuilt 第三方应用

与 `prebuilt/`（内核工件，二进制不入库）不同，本目录存放**构建必需的第三方预编译应用**。
APK 体积在 Git 可接受范围内，因此随仓库分发，保证 clone 即可构建。

| 应用 | 包名 | 用途 |
|---|---|---|
| `OpenEUICC` | `im.angry.openeuicc` | eSIM LPA（Local Profile Assistant）。设备无原厂 LPA，靠它管理 eSIM profile |

## OpenEUICC

- 上游：<https://gitea.angry.im/PeterCxy/OpenEUICC>
- 以 `android_app_import` 引入，`certificate: "platform"`、`privileged: true`、装入 `system_ext`
- 配套 `privapp_whitelist_im.angry.openeuicc.xml` 授予特权权限
- `dex_preopt` 关闭（预编译 APK 无需再优化）

升级时替换 `OpenEUICC.apk` 并核对 `Android.bp` 里的 `certificate` 是否仍匹配。
