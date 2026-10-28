# prebuilt 内核工件（不入 Git）

`tools/sync-prebuilts.sh` 把已验收的内核工件拷到这里，构建时由 `BoardConfig.mk` 引用：

| 文件 | 来源 | 用途 |
|---|---|---|
| `Image` | 自编内核 `4.19.81-gaea-R48`（含 binderfs + 内建 rt1011） | `TARGET_PREBUILT_KERNEL` |
| `dtb/dtb` | 原厂 `dt_table`（`stock_dt_table.img`） | `BOARD_PREBUILT_DTBIMAGE_DIR` |
| `dtbo.img` | 原厂 `dtbo_a` 备份 | `BOARD_PREBUILT_DTBOIMAGE` |

三者都必须与当前 vendor 匹配；换内核时重跑脚本，并同步更新 `A13-PORT-PLAN` 的验收集。
