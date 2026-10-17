# Benchmark Pilot Handoff（已完成）

> 2026-10-17：benchmark pilot 的 **1 task × 2 methods dry run** 已完成。
> 本文原为长会话压缩时的交接；完成后保留为入口，指向归档记录。
> **没有方法效果结论；README 的 `[ ] 对照测量` 仍未勾选。**

## 结果在哪

- 计划与工人汇报：`.foreman/archive/2026-10-17-benchmark-pilot/`
  - `PLAN.md`
  - `STATUS.md`（含两个 run 的 session / usage / wall-clock / grader 证据）
- 原始证据：`benchmarks/runs/20261017T071751Z-A-sum-cli/`、
  `benchmarks/runs/20261017T071912Z-B-sum-cli/`（gitignored，不提交）
- 协议：`docs/benchmark-protocol.md`

## 这次 dry run 是什么

- 任务：`sum-cli`；方法 A 单 agent，方法 B agent-foreman；各 1 run。
- 两个 run 都通过评分器；方法 B 的 REVIEW 为 PASS。
- 这是流程验证，不是正式对照：只有 1 个任务、没有顺序平衡，且工具权限环境不是对称的；
  不能据此判断哪种方法更好或更便宜。

## 下一步

如果要正式对照，至少需要：统一两边的 MCP / 工具环境、3 个任务、A→B / B→A 顺序平衡，
并由人另批预算和新 PLAN。现在没有授权扩展。
