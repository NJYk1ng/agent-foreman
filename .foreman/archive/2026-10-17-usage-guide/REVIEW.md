# REVIEW — 编写 agent-foreman 实际使用指南

> 领导：Codex · 2026-10-17 · 对象：归档 T15 PLAN / STATUS 与实现提交 `c8e106f`

## 结论：BLOCK

### [P1] AC2 的独立复现失败，STATUS 未提供实际检查命令 —— `.foreman/archive/2026-10-17-usage-guide/PLAN.md:30-33`

按 PLAN 中的 Python 检查原样运行，断言失败并报告缺少 `没有 .foreman/PLAN.md`。文档在 [docs/usage.md](../../../docs/usage.md) 中用 Markdown 反引号包住 `.foreman/PLAN.md`，语义说明存在，但 PLAN 的字面子串检查不匹配。STATUS 的 AC2 命令块用 `... required items check ...` 省略了实际脚本，因此无法证明工人运行的是 PLAN 中这条检查。AC2 未通过，不能接受 STATUS 的 `DONE`。按要求未改 PLAN / STATUS。

### [P2] STATUS 提交字段没有记录实现提交 SHA —— `.foreman/archive/2026-10-17-usage-guide/STATUS.md:3`

STATUS 写作 `c67b5a0 + 本次改动`，其中 `c67b5a0` 是计划基线；实际实现提交为 `c8e106f`。归档记录的提交来源不准确。按要求未改 STATUS。

## 对照验收标准

- T15/AC1 `[命令]` ✅ 独立运行 `test -s docs/usage.md`，退出码 0。
- T15/AC2 `[命令]` ❌ 按归档 PLAN 中的检查脚本独立复现失败：缺少字面子串 `没有 .foreman/PLAN.md`；STATUS 中仅有省略版命令块，不能复核其 PASS 输出。
- T15/AC3 `[命令]` ✅ 独立运行 `./install.sh --help | grep -F -- '--project' && bash scripts/notify-lead.sh --help | grep -F -- '--status'`，两个选项均命中；三个 skill 名称 `rg` 检查均命中对应文件。
- T15/AC4 `[命令]` ✅ 独立重跑完整回归链：`foreman-check` 通过、checker `7/7`、install `33/33`、notify-lead `24/24`、链接检查 26 项、fixtures `3 tasks OK`；链式命令退出码 0。
- T15/AC5 `[命令]` ✅ `git diff --check` 退出码 0；限制范围的 `git diff` 无输出；T15 实现提交的产品文件仅为 `docs/usage.md`。
