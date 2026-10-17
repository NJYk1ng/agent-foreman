# REVIEW — 编写 agent-foreman 实际使用指南

> 领导：Codex · 2026-10-17 · 复验对象：T15 PLAN / STATUS，原实现 `c8e106f`，AC2 退出码修正 `3e460af`

## 结论：PASS

无发现。

复验更正：上一版 REVIEW 把归档 STATUS 中不存在的标题循环当成 AC2 命令的一部分，因而误报 AC2 失败。按 `3e460af` 后 STATUS 中实际记录的 AC2 块重新核对并执行，不含标题循环；Python 检查与工作流顺序断言均通过，`ac2_rc=0`。

## 对照验收标准

- T15/AC1 `[命令]` ✅ 独立运行 `test -s docs/usage.md`，退出码 0；文档包含全局安装与 `--project` 区别、新项目开场 A/B、完整流程、常见坑与常用命令。
- T15/AC2 `[命令]` ✅ 独立运行 STATUS 中实际记录的完整检查：输出 `usage guide required items: OK`；工作流位置为 `[2392, 2405, 2411, 2434, 2448, 2456, 2477, 2487]`；实际捕获 `ac2_rc=0`。
- T15/AC3 `[命令]` ✅ 安装器帮助命中 `--project`，`notify-lead` 帮助命中 `--status`；三个 skill 名称检查均命中对应文件。
- T15/AC4 `[命令]` ✅ 独立重跑完整回归链：`foreman-check` 通过、checker `7/7`、install `33/33`、notify-lead `24/24`、链接检查 26 项、fixtures `3 tasks OK`；链式命令退出码 0。
- T15/AC5 `[命令]` ✅ `git diff --check` 退出码 0；限制范围的 `git diff` 无输出。对照 `c67b5a0..c8e106f`，产品改动仅新增 `docs/usage.md`，符合 PLAN 边界。
