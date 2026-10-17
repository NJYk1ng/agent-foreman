# REVIEW — T3 让 notify-lead 明确选择正确的交互会话

> 领导：Codex · 2026-10-17 · 对象：`1896a09`（实现）、`4cbfbac`（STATUS）

## 结论：PASS

无发现。

## 对照验收标准

- T3/AC1 `[命令]` ✅ 独立运行 `bash tests/test-notify-lead.sh`，`PASS=17 FAIL=0`。较新的 subagent 与 `codex_exec` 均被跳过，只选中夹具中的交互会话。
- T3/AC2 `[命令]` ✅ 同一套件通过 `--thread` 显式指定和 symlink 项目路径按 realpath 匹配；无交互会话时返回 12，并给出可操作错误信息。
- T3/AC3 `[命令]` ✅ 同一套件通过 schema 不兼容（退出 11）、会话库缺失（退出 10）和 `python3` 缺失（退出 5）的退出码与错误信息检查。
- T3/AC4 `[命令]` ✅ 独立运行 `bash -n scripts/notify-lead.sh`，退出码 0。
- 回归保护 ✅ 独立运行 `bash tests/test-install.sh`，`PASS=26 FAIL=0`。
- 真实库只读验证 ✅ 用真实默认 Codex 会话库运行选择逻辑，`sqlite3` 以 `mode=ro` 打开；PATH 中以临时假 `codex` 替代真实命令。捕获到选择主交互会话 `01a14810-e903-73c2-b486-d74084806a01`，未选择更新的 Guardian subagent，也未调用真实 `codex queue`。

STATUS 中 5 个命令/输出证据块均已独立复核。另运行 `git show --check --oneline 1896a09`，退出码 0。
