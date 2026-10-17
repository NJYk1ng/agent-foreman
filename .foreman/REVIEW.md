# REVIEW — T2 修复安装器卸载、覆盖备份和冲突提示

> 领导：Codex · 2026-10-17 · 对象：`6d352dc`（实现）、`9e23b23`（STATUS）

## 结论：BLOCK

### [P1] 卸载前只检查结束标记是否存在，错序时仍会删除用户尾部内容 —— `install.sh:76`

当全局文件里有一条孤立的结束标记、其后出现未闭合的开始标记时，`check_global_marker_pair` 因为能在文件任意位置找到结束标记而放行。卸载解析器也只检查 `end is None`，没有验证结束标记位于开始标记之后；于是它会从未闭合的开始标记处丢弃剩余内容，并以退出码 0 报告成功。独立复现：临时 HOME 的 `CLAUDE.md` 内容设为“KEEP-BEFORE / 结束标记 / KEEP-AFTER / 开始标记 / SENTINEL-TAIL”，再运行 `install.sh --uninstall`；命令退出 0，结果文件只剩 `KEEP-BEFORE` 和孤立结束标记，`KEEP-AFTER` 与 `SENTINEL-TAIL` 被删除。应先验证标记严格成对且顺序正确，否则在任何修改前拒绝操作。

## 对照验收标准

- T2/AC1 `[命令]` ❌ 常规“没有任何结束标记”的回归用例通过；但错序的孤立结束标记绕过 preflight 并导致数据删除，因此“开始标记缺少其结束标记时拒绝修改”未完整满足。
- T2/AC2 `[命令]` ✅ `bash tests/test-install.sh` 中默认安装保留用户 skill，`--force` 安装仓库版本并生成内容可恢复的备份；23 个断言全部通过。
- T2/AC3 `[命令]` ✅ `bash tests/test-install.sh` 中冲突提示可用且不自引用 `@AGENTS.md`；默认安装保留用户 `AGENTS.md`，`--force` 前备份原文件。
- T2/AC4 `[命令]` ✅ 独立运行 `bash -n install.sh`，退出码 0。
- 边界补充 ✅ 回归脚本覆盖正常卸载保留标记段外内容、符号链接全局文件及用户改过的 `notify-lead`，全部通过。

STATUS 中 4 个 AC 证据块已通过独立重跑回归脚本及 `bash -n install.sh` 核对；另运行 `git show --check --oneline 6d352dc`，退出码 0。
