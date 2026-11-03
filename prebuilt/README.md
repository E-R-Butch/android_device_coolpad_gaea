# prebuilt 内核工件

本目录只放**验收集**内核工件，二进制不入 Git（见 `.gitignore` 白名单）。

| 文件 | 来源 | 说明 |
|---|---|---|
| `Image` | `/root/work/fod-r48/Image-R48` | R48 验收集：binderfs 兼容层 + `rt1011` 内建；sha256 `c3e39edc…`，30,930,956 B，版本 `4.19.81-gaea-R48 #48` |
| `dtbo.img` | 原厂 `dtbo_a` 实测导出 | 25,165,824 B，sha256 `828491a9…` |

换内核时重跑 `tools/sync-prebuilts.sh <Image> <dtbo.img>`，并把新的 sha256 / 版本串更新到
`rom-porting/A13-PORT-PLAN-*.md` 的验收集记录里，然后重新 `lunch` + `m nothing`。

判据：`m nothing` 通过，且 `sha256sum prebuilt/Image` 与验收集记录一致。
