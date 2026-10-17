# PLAN — 固定 CI 环境并准备对照测量

> 领导：Codex · 2026-10-17 · 来源：人明确发起的新计划

## 背景与约束

T1–T7 与 T8–T10 已完成并归档；当前 `master` 与 `origin/master` 同步，工作区干净，现有 CI 为绿（按人提供的状态）。
GitHub 官方已发布 `actions/checkout` v7.0.1；Ubuntu `-latest` 到 26.04 的迁移将于 2026-10-19 开始，计划在 2026-11-19 前完成（[checkout release](https://github.com/actions/checkout/releases/tag/v7.0.1)、[GitHub migration notice](https://github.blog/changelog/2026-09-17-ubuntu-26-generally-available-and-latest-migration/)）。
本轮对照测量只做协议与最小任务集/夹具，不运行 Codex / Claude pilot，也不消耗订阅或 API 额度；pilot 留待协议完成后另立计划并由人明确预算。
push、重启、版本 tag / changelog 属于人的部署动作，不列为实现任务；不写任何未测量的效果结论。
所有实现均由工人完成；任一任务卡住两次，工人写 `.foreman/BLOCKED.md`，由人决定是否请领导给方向或改计划。

## 任务

### T11 固定 CI runner 与 checkout 运行时

- **目标**：GitHub Actions 使用固定的 Ubuntu 24.04 runner 和支持 Node.js 24 的 checkout 版本，同时保留现有 CI 命令。
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `rg -n 'runs-on: ubuntu-24\.04' .github/workflows/ci.yml` → 命中 CI job 的 runner 配置。
  - AC2 [命令] `rg -n 'actions/checkout@v7\.0\.1' .github/workflows/ci.yml` → 命中 checkout 步骤。
  - AC3 [观察] 对照 T11 基线提交检查 `.github/workflows/ci.yml` 的 diff → 仅 runner / checkout 版本有变化；原有 `foreman-check`、`test-install`、`test-notify-lead`、`test-foreman-check` 命令及参数保持不变。
  - AC4 [命令] `git diff --check` → 退出码 0。
  - AC5 [现场] 人 / GitHub Actions 中 T11 提交对应的 workflow run / 查看 job 结果与 annotations → 所有步骤通过，且没有 Node.js 20 弃用 annotation。此项须在人工执行部署动作、提交到 GitHub 后验证；工人不得代替人判通过。
- **边界**：不改现有 CI 命令和测试；不执行 push；不更改 runner 以外的工作流触发条件或权限。

### T12 定义对照测量协议并建立最小任务集/夹具

- **目标**：形成可复跑、可审计的领导制与单 agent 对照协议及最小隔离夹具，供未来经人批准预算后运行 pilot。
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `python3 benchmarks/check_fixtures.py` → 至少 3 个任务夹具通过校验；每个任务有固定起始快照、参与者可见的任务说明、独立评分器和隐藏测试；评分器 / 隐藏测试不位于 agent 可访问的任务工作区中，校验失败时退出非零并指出任务和字段。
  - AC2 [观察] 检查 `docs/benchmark-protocol.md` → 明确定义两种方法的相同任务集、相同起始状态与提示约束、独立会话/工作区、任务顺序平衡、原始证据保存；逐项定义 token 成本、wall-clock 起止点、隐藏测试缺陷漏出率分母/分子、人工介入次数。
  - AC3 [观察] 检查协议中的额度与报告规则 → token usage 只能从会话日志 / usage 证据读取，缺失时记为不可用而不估算；任何 pilot 运行须由人另行批准预算并另立计划；本任务只建立协议和夹具，不运行 agent，也不报告效果结论。
  - AC4 [命令] `git diff --check` → 退出码 0。
- **边界**：不运行真实 Codex / Claude 会话或 API 调用；不采集真实订阅用量；不把 pilot 结果、成本优势或缺陷率结论写入文档；不改 README 中待测量状态。协议与夹具完成后，是否开 pilot 由人根据预算另行决定。
