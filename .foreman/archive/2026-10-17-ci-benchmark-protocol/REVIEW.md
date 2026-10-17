# REVIEW — T12 对照测量协议与夹具

> 领导：Codex · 2026-10-17 · 对象：`981ba4f`（实现）/ `7e1f914`（STATUS）

## 结论：PASS

### [P2] 隐藏测试副本可能泄入 agent workspace —— `benchmarks/check_fixtures.py:128-135`

校验器只检查 `metadata.json` 的 `hidden_tests` 路径是否在 workspace 外；它不检查未列入该字段的文件是否是 grader / 隐藏测试副本。我在临时副本中把 `grader/test_sum.sh` 复制到 `workspace/leaked-test.sh`，同步更新快照 SHA-256 后，校验器仍以 `fixtures: 3 tasks OK`、退出码 0 通过。未来夹具若误把隐藏测试复制进可见 workspace，会泄露评分内容。建议校验 workspace 中不存在 grader 文件副本，或通过明确的可见文件清单约束 workspace 内容。此项不阻塞本轮，但应在任何 pilot 前修正。

### [P2] token 汇总未定义 cache 字段的去重规则 —— `docs/benchmark-protocol.md:54-56`

协议要求记录 input、output、cache read/write 并汇总为总 token，却未说明各 provider 的 cache 字段可能是 input 的子集还是独立部分。若 usage 记录 `input_tokens=100` 且其中 `cached_tokens=80`，把两者相加会把 input 计为 180；OpenAI 文档将 cached tokens 定义为 input token 的 breakdown（[API reference](https://platform.openai.com/docs/api-reference/realtime-server-events/response/function_call_arguments/done?lang=python)）。跨 provider 比较前应定义按 provider 归一化的计算方式，或使用来源提供的 canonical total，避免重复计数。此项不阻塞本轮；pilot 前需明确。

## 对照验收标准

- T12/AC1 `[命令]` ✅ 独立运行 `python3 benchmarks/check_fixtures.py`：3 个夹具均通过；起始快照失败、solution 通过。额外负向演示发现上述隐藏测试副本漏检 P2。
- T12/AC2 `[观察]` ✅ 核对 `docs/benchmark-protocol.md`：包含两种方法、相同任务集 / 起点 / 提示约束、独立会话 / 工作区、顺序平衡、原始证据及四项指标定义。token cache 归一化缺口另记 P2。
- T12/AC3 `[观察]` ✅ 协议明确不授权 pilot、usage 缺失记 `unavailable`、本任务不运行 agent / 采集真实用量 / 写效果结论；README 的对照测量仍未勾选。复核中没有运行真实 Codex / Claude 会话或 API。
- T12/AC4 `[命令]` ✅ 独立运行 `git diff --check`：退出码 0。

STATUS 中的 AC1、AC4 命令块均已独立重跑；另独立运行完整回归链，退出码 0：foreman-check 通过，负向测试 `PASS=7 FAIL=0`，安装器 `PASS=33 FAIL=0`，notify-lead `PASS=24 FAIL=0`，链接检查 26 个本地链接 / 锚点通过。另检查 `981ba4f` 与 `7e1f914` 的提交空白，`git show --check` 均通过。T11/AC5 仍是现场待验项，不在本次 T12 结论范围内。
