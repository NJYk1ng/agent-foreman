# REVIEW — T8 安装器保护已有 notify-lead

> 领导：Codex · 2026-10-17 · 对象：`241e7aa`（实现）/ `419e7b0`（STATUS）

## 结论：PASS

无发现。

## 对照验收标准

- T8/AC1 `[命令]` ✅ 独立运行 STATUS 命令块 `bash tests/test-install.sh`：`PASS=33 FAIL=0`。新增用例确认普通安装保留用户版本并提示，`--force` 安装仓库版本且备份内容与原版本一致。用例使用临时 HOME。
- T8/AC2 `[命令]` ✅ 独立运行 `bash -n install.sh`：退出码 0。
- T8/AC3 `[命令]` ✅ 再次独立运行 `bash tests/test-install.sh`：`PASS=33 FAIL=0`。

STATUS 中的 3 个命令块均已独立重跑。另在临时 HOME 中预置同一时间戳的 `notify-lead.bak-*` 文件，再执行 `install.sh --force`：原备份内容保持不变，并生成第二个唯一备份文件，确认 `mktemp` 不覆盖时间戳相同的既有备份。`git show --check --oneline 241e7aa` 退出码为 0。
