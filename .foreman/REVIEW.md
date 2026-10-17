# REVIEW — T2 修复安装器卸载、覆盖备份和冲突提示（复审）

> 领导：Codex · 2026-10-17 · 对象：`6d352dc` + 修复 `de23aad`，STATUS `da9b88b`

## 结论：PASS

无发现。首轮 P1 已修复。

## 对照验收标准

- T2/AC1 `[命令]` ✅ 独立运行 `bash tests/test-install.sh`，缺结束标记与标记错序用例均以退出码 3 拒绝操作，文件逐字节不变。另以临时 HOME 独立重现首轮错序场景：结束标记先于未闭合的开始标记，`install.sh --uninstall` 返回退出码 3，并输出 `FILE_UNCHANGED`。
- T2/AC2 `[命令]` ✅ 同一回归运行通过默认安装保留用户 skill、`--force` 安装仓库版本及备份与原版本一致的断言。
- T2/AC3 `[命令]` ✅ 同一回归运行通过 `AGENTS.md` 冲突提示可用且不自引用、默认不覆盖及 `--force` 备份原文件的断言。
- T2/AC4 `[命令]` ✅ 独立运行 `bash -n install.sh`，退出码 0。
- 边界补充 ✅ 回归通过正常卸载保留标记段外内容、全局文件符号链接和用户改过的 `notify-lead` 断言。

STATUS 的 5 个代码块均已独立核对；`bash tests/test-install.sh` 输出 `PASS=26 FAIL=0`。另运行 `git show --check --oneline de23aad`，退出码 0。
