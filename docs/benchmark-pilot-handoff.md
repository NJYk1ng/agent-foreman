# Benchmark Pilot Handoff

> 写于 2026-10-17。目的：在长会话压缩 / 切换后，用一个文件恢复 benchmark pilot 所需的全部状态。
> **本文件不包含任何 pilot 结果；pilot 尚未运行。**

## 1. 当前仓库状态

- `master == origin/master`；写本文件前的 HEAD：`9727612`（之后会多一个 handoff 提交）。
- 工作区干净。
- 最近一次 CI（archive commit `9727612`）：run `39011947021`，`test` 6s，全绿；
  runner `ubuntu-24.04`，`actions/checkout@v7.0.1`，annotations 0。
- `.foreman/` 根目录**没有活跃 PLAN**；历史计划都在 `.foreman/archive/`：
  - `2026-10-17-self-review`
  - `2026-10-17-collaboration-fixes`
  - `2026-10-17-installer-ci-docs`
  - `2026-10-17-ci-benchmark-protocol`
- 已安装副本（`~/.claude/skills`、`~/.codex/skills`、两边全局记忆、
  `~/.local/bin/notify-lead`）在 T8–T10 部署时更新；T11–T12 没有再改它们。

## 2. Benchmark 基础设施

- 协议：`docs/benchmark-protocol.md`
- 夹具校验：`python3 benchmarks/check_fixtures.py` → `fixtures: 3 tasks OK`
- 任务：
  - `benchmarks/tasks/wordcount/`（Python）
  - `benchmarks/tasks/sum-cli/`（Bash）
  - `benchmarks/tasks/tag-normalize/`（Python）
- 每个任务有：固定 `workspace/` + SHA-256、`task.md`、`grader/` + 隐藏测试、
  `solution/`；`metadata.visible_files` 防止隐藏测试副本进入 workspace。
- 原始证据目录：`benchmarks/runs/<run-id>/`（`.gitignore` 已忽略，不提交）。

## 3. 下一步：pilot 需要新计划 + 预算

按 T12 协议，**pilot 必须由人另行批准预算并另立计划**。
T12 只建了协议和夹具，没有运行 agent，也没有采集真实用量。

建议先让 Codex（领导）写新的 `.foreman/PLAN.md`，内容至少包括：

- **范围**：先做 1 个任务的 dry run（1 task × 2 methods = 2 runs），验证夹具、
  评分和记录流程；再由人决定是否扩到 3 tasks × 2 methods（6 runs），
  或加做顺序平衡的第二轮（12 runs）。
- **预算**：人给出 token / 金额 / 时间上限；token 从会话日志 / usage 读取，
  缺失记 `unavailable`，不估算。
- **方法**：
  - A 单 agent：一个会话从 `task.md` 到提交；
  - B agent-foreman：Codex 写 PLAN / 审 REVIEW，Claude 工人实现 / 自证。
- **控制**：独立会话 / workspace、同一固定快照、禁止访问
  `grader/` / `solution/` / 隐藏测试、记录运行顺序；原始证据落 `benchmarks/runs/`。
- **交付**：pilot 记录（不含效果结论）；只有真实测量后才更新 README 的
  `[ ] 对照测量`。

## 4. 压缩 / 新会话后的第一句

> 读 docs/benchmark-pilot-handoff.md，按里面的下一步继续；
> 先让 Codex 写 benchmark pilot 的 PLAN，不要直接跑；预算和范围等我确认。

## 5. 不要做的事

- 不要直接运行 Codex / Claude pilot；先有 PLAN + 人的预算批准。
- 不要估算缺失的 token；不要写“更便宜 / 更可靠”的结论。
- 不要把 grader / 隐藏测试 / solution 放进 agent 可见 workspace。
- 不要改 README 的 `[ ] 对照测量`，除非 pilot 真的跑完并有数据。
