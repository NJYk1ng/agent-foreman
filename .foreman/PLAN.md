# PLAN — Benchmark pilot dry run

> 领导：Codex · 2026-10-17 · 来源：需求方明确发起；依据 `docs/benchmark-pilot-handoff.md` 与 `docs/benchmark-protocol.md`

## 背景与约束

- Benchmark 协议与 3 个夹具已建立，但尚未运行真实 pilot。
- 本计划提议先用 1 个任务 × 2 种方法，共 2 runs，验证夹具、评分和记录流程；建议任务为 `sum-cli`，由需求方确认或指定其他现有夹具。
- 方法 A：单 agent，一个会话从 `task.md` 做到提交。方法 B：agent-foreman，Codex 领导写 `PLAN.md` / 审 `REVIEW.md`，Claude 工人实现 / 自证 / 写 `STATUS.md`。
- 这只是流程 dry run，不足以形成方法效果结论；是否扩到 3 tasks、是否做顺序平衡由人另行决定，本计划不授权扩展。
- **预算闸门**：token 上限、金额上限、耗时上限都待人明确填写并确认；未知值不得填 0 或估算。收到范围与全部预算上限的明确批准之前，不得创建会话、运行 agent、评分或消耗 pilot 额度。
- 两种方法使用独立会话和独立 workspace 副本，起点均为所选任务的同一固定快照；agent 只读 `task.md`，不得读取 `grader/`、`solution/` 或隐藏测试。
- 每次运行的原始证据落在 `benchmarks/runs/<run-id>/`；token 只从会话日志/provider usage 读取，缺失记 `unavailable`。不改 README 的 `[ ] 对照测量`。

## 人工确认项（开工前必填）

- 范围：需求方已确认仅做 1 task × 2 methods = 2 runs；不扩到 3 tasks，不做顺序平衡。
- 任务：`sum-cli`。
- token 总上限：500,000（两次 run 合计）；实际值只从 usage 读取，缺失记 `unavailable`。
- 金额总上限及币种：CNY 0 额外按量支出（订阅内）；若出现按量计费，立即停止并报告。
- 总耗时上限：60 分钟（T13 两次 run 合计 wall-clock，不含本次计划确认时间）。
- 方法 A 执行者：Claude Code 单会话；与方法 B 的工人使用同一模型。
- 执行方式：每次 run 使用全新 CLI 会话（`claude -p` / `codex exec`），不使用当前 live 会话，避免夹具认知污染。
- 启动授权：需求方已授权 Codex 确认上述数值；T13 开工门槛已满足。

## 任务

### T13 单任务双方法 benchmark dry run

- **目标**：在需求方明确确认范围与预算后，对同一个固定任务快照各执行一次方法 A 和方法 B，并把可核查的原始证据及流程结果保存下来，不得据此声称哪种方法更好。
- **谁写**：工人
- **依赖**：无（需求方已确认“人工确认项”中的任务、范围、token / 金额 / 耗时上限，并授权启动；T13 可开工）。
- **验收标准**：
  - AC1 [现场] 需求方 / 本对话的计划确认环节 / 明确填写并批准任务 ID、仅 2 runs 的范围，以及 token、金额、耗时三项上限 / 三项上限均为明确数值或明确额度值、任务与范围确定且有明确启动授权，才算满足开工门槛；否则 T13 不得启动。
  - AC2 [命令] `python3 benchmarks/check_fixtures.py` → `fixtures: 3 tasks OK`；运行所选任务前，所用 workspace 快照的 SHA-256 与该任务 `metadata.json` 中记录值一致。
  - AC3 [观察] `benchmarks/runs/` 下恰有本次两个唯一 run-id 的原始记录；每个记录含方法、任务 ID、独立会话 ID、独立 workspace 路径、任务快照 SHA-256、运行顺序、UTC 起止时间、最终 diff、评分器原始输出、人工介入记录及 usage 原始字段或 `unavailable`；两份记录所用任务 ID 与快照 SHA-256 相同，session/workspace 不复用。
  - AC4 [观察] 两个 agent workspace 的文件清单都与所选夹具 `metadata.visible_files` 一致；`grader/`、`solution/`、隐藏测试不在 workspace 中，也未提供给 agent。评分只在 agent workspace 之外运行，并将原始结果保存在对应 run 记录中。
  - AC5 [观察] 两份记录分别能追溯到方法 A（单 agent、一个会话从 `task.md` 到提交）和方法 B（agent-foreman 协作流程）；token 只引用日志 / provider usage 的原始字段，缺失记 `unavailable`，不补 0、不估算；同时记录 wall-clock 和人工介入，缺失项明确标 unavailable 或未发生。
  - AC6 [命令] `git diff --check` → 退出码 0；结果摘要写入 `.foreman/STATUS.md`，只报告实际观测，不写比较性结论，README 的 `[ ] 对照测量` 保持未勾选。
- **边界**：不得在人工确认前启动 pilot 或使用真实 Codex / Claude / API 额度；不得增加任务数、运行轮数或自行做顺序平衡；不得读取、复制、展示或提交 grader / solution / 隐藏测试；不得估算 token、金额或耗时；不得据 dry run 声称效果优劣；不得改 README 的 `[ ] 对照测量`。

> 升级点：若会话隔离、快照一致性、隐藏测试隔离或证据读取任一关键环节连续卡住两次，工人写 `.foreman/BLOCKED.md` 并停止；由人决定是否请领导给方向或改计划。不得以降低隔离/证据要求来继续运行。
