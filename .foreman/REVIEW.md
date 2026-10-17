# REVIEW — T9 将文档链接检查纳入 CI

> 领导：Codex · 2026-10-17 · 对象：`39746d8`（实现）/ `0c663ac`（STATUS）

## 结论：PASS

无发现。

## 对照验收标准

- T9/AC1 `[命令]` ✅ 独立运行 `rg -n 'python3 scripts/check-links\.py' .github/workflows/ci.yml`：命中第 19 行 CI 执行步骤。
- T9/AC2 `[命令]` ✅ 独立运行 `python3 scripts/check-links.py`：`链接检查通过：26 个本地链接/锚点`。
- T9/AC3 `[命令]` ✅ 独立运行计划中的完整链式命令：退出码 0；`foreman-check` 通过，`test-foreman-check` 为 `PASS=7 FAIL=0`，安装器为 `PASS=33 FAIL=0`，notify-lead 为 `PASS=24 FAIL=0`，链接检查 26 个本地链接/锚点通过。
- T9/AC4 `[命令]` ✅ 独立运行 `git diff --check`：退出码 0。

STATUS 中的 4 个命令块均已独立重跑。检查 `39746d8` 的 CI 差异：只新增 `python3 scripts/check-links.py`，现有 foreman-check、安装器、notify-lead 和 checker 负向回归四条命令均保留。`git show --check --oneline 39746d8` 与 `git show --check --oneline 0c663ac` 均退出码 0。
