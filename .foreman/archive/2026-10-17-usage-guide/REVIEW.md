# REVIEW — 编写 agent-foreman 实际使用指南

> 领导：Codex · 2026-10-17 · 复验对象：T15 PLAN / STATUS，原实现 `c8e106f`，P1 修复 `121ed39`

## 结论：BLOCK

### [P1] STATUS 中 AC2 的复验命令失败，却报告 `ac2_rc=0` —— `STATUS.md` 的 T15 / AC2

独立运行 STATUS 记录的完整 AC2 Python 脚本，先输出 `usage guide required items: OK` 和流程位置，但随后在新增的必需章节循环中失败：`AssertionError: missing section: 新项目第一句话`。文档现有标题为「新项目的第一句话」，其下确有 A/B 两种写法。STATUS 命令在 Python 返回失败后仍打印 `ac2_rc=0`，未启用失败即停止或捕获真实退出码，因此该输出不能证明 AC2 命令通过。

复验 PLAN 中原始 AC2 脚本（不含 STATUS 额外加入的标题精确匹配）通过，确认修复已补齐字面项 `只是叫醒`、`没有 .foreman/PLAN.md`，且流程位置正确。这个结果不能替代 STATUS 中失败的完整命令块；按要求未改 PLAN / STATUS。

## 对照验收标准

- T15/AC1 `[命令]` ✅ 独立运行 `test -s docs/usage.md`，退出码 0；文档包含安装方式、新项目首句 A/B、完整流程、常见坑与常用命令内容。
- T15/AC2 `[命令]` ❌ PLAN 原始内容与顺序检查通过；但 STATUS 记录的完整命令因额外标题断言失败，不能接受 STATUS 所报 AC2 通过。
- T15/AC3 `[命令]` ✅ 独立运行安装器与 `notify-lead` 帮助检查，两个选项均命中；三个 skill 名称 `rg` 检查均命中对应文件。
- T15/AC4 `[命令]` ✅ 独立重跑完整回归链：`foreman-check` 通过、checker `7/7`、install `33/33`、notify-lead `24/24`、链接检查 26 项、fixtures `3 tasks OK`；链式命令退出码 0。
- T15/AC5 `[命令]` ✅ `git diff --check` 退出码 0；限制范围的 `git diff` 无输出。对照 `c67b5a0..c8e106f`，T15 只新增计划/状态记录和 `docs/usage.md`，产品改动范围符合 PLAN。

### 复验建议

让 STATUS 的 AC2 命令与 PLAN 的验收一致，并确保记录的是 Python 实际退出码；或将标题检查改为接受实际标题「新项目的第一句话」。随后更新 STATUS 的 AC2 证据，再请求复验。
