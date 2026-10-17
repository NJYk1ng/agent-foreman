# PLAN — Benchmark pilot 完成后的文档与生成物清理

> 领导：Codex · 2026-10-17 · 来源：需求方明确发起；基于当前 HEAD `4f0e4ca` 与已归档的 pilot 记录

## 背景与约束

- Benchmark pilot 的 1 task × 2 methods dry run 已于 2026-10-17 完成，记录在 `.foreman/archive/2026-10-17-benchmark-pilot/`；两个 run 评分通过，但 dry run 不产生方法效果结论。
- `docs/benchmark-protocol.md` 和一次性交接 `docs/benchmark-pilot-handoff.md` 仍保留 pilot 前状态；`benchmarks/__pycache__/` 是 gitignored 生成物。
- 本轮只做这三项小清理，保持 README 的 `[ ] 对照测量` 未勾选；不改代码或夹具，不提交 `benchmarks/runs/`。
- 交接文件处理方式：将 `docs/benchmark-pilot-handoff.md` 改成简短的“pilot 已完成”指引，链接到归档记录；保留文件路径，避免旧入口继续给出过时指令。

## 任务

### T14 清理 benchmark pilot 状态与生成物

- **目标**：移除 benchmark Python 缓存，并让协议与 handoff 准确指向已完成的 dry run，同时保留“无效果结论 / README 复选框未勾选”的状态。
- **谁写**：工人
- **依赖**：需求方确认本计划后开始。
- **验收标准**：
  - AC1 [命令] 所有 Python 检查与测试完成后执行 `rm -rf benchmarks/__pycache__ && test ! -e benchmarks/__pycache__` → 退出码 0；删除范围仅限该缓存目录。
  - AC2 [观察] `docs/benchmark-protocol.md` 顶部状态明确写出 `2026-10-17` 已完成 `1 task × 2 methods` dry run，并链接 `.foreman/archive/2026-10-17-benchmark-pilot/`；同段明确没有方法效果结论，README 的 `[ ] 对照测量` 保持未勾选。
  - AC3 [命令] `rg -n 'benchmark-pilot|2026-10-17|dry run|已完成' docs/benchmark-pilot-handoff.md` → handoff 是简短完成说明并指向归档；`! rg -n '尚未运行 pilot|先让 Codex|T12 只建了协议|预算等我确认' docs/benchmark-pilot-handoff.md` → 退出码 0（不再包含过时的未运行 / 待启动指引）。
  - AC4 [命令] `./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh && python3 scripts/check-links.py && python3 benchmarks/check_fixtures.py` → 整条命令退出码 0；链接检查通过，夹具仍报告 `fixtures: 3 tasks OK`。
  - AC5 [命令] `git diff --check` → 退出码 0；`git diff --exit-code -- README.md README.en.md` → 退出码 0；README 的 `[ ] 对照测量` 仍未勾选。
- **边界**：只改 `docs/benchmark-protocol.md` 与 `docs/benchmark-pilot-handoff.md`，并删除 `benchmarks/__pycache__/`；不改代码、测试、夹具、README 或归档内容；不提交 `benchmarks/runs/`；不添加 pilot 效果结论或据两次 dry run 推断方法优劣。
