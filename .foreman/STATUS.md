# STATUS — 固定 CI 环境并准备对照测量

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：ff0f47c（T11）、981ba4f（T12）；本 STATUS 随后单独提交

## T11 固定 CI runner 与 checkout 运行时 — 状态：UNVERIFIED

- **AC1 [命令]**: ✅
  ```
  $ rg -n 'runs-on: ubuntu-24\.04' .github/workflows/ci.yml
  9:    runs-on: ubuntu-24.04
  ```

- **AC2 [命令]**: ✅
  ```
  $ rg -n 'actions/checkout@v7\.0\.1' .github/workflows/ci.yml
  11:      - uses: actions/checkout@v7.0.1
  ```

- **AC3 [观察]**: ✅ 只改了 runner 和 checkout 两行；现有命令与参数未动：
  ```
  $ git diff -- .github/workflows/ci.yml
  @@ -6,9 +6,9 @@
   jobs:
     test:
  -    runs-on: ubuntu-latest
  +    runs-on: ubuntu-24.04
       steps:
  -      - uses: actions/checkout@v4
  +      - uses: actions/checkout@v7.0.1
  ```
  `run:` 块中的 foreman-check / test-install / test-notify-lead /
  test-foreman-check / check-links 全部保持原样。

- **AC4 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **AC5 [现场]**: ⏳ 待现场验证 —— 容器里没有 GitHub Actions 环境。
  - 复现步骤：
    1. `git push origin master`
    2. 打开 https://github.com/NJYk1ng/agent-foreman/actions，找到 T11 提交对应的 run
    3. 查看 `test` job 的所有步骤是否全绿；annotations 中是否还有 Node.js 20 弃用
  - 判据：所有步骤绿，且没有 Node.js 20 annotation = 通过。

- **改动**：`.github/workflows/ci.yml`
- **提交**：`ff0f47c`
- **边界核对**：未改现有 CI 命令/测试；未执行 push。
- **备注**：T11 的 AC5 是现场项，工人不判通过；状态因此是 `UNVERIFIED`，不是 `DONE`。

---

## T12 定义对照测量协议并建立最小任务集/夹具 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ python3 benchmarks/check_fixtures.py
  ✅ sum-cli: structure + snapshot
  ✅ sum-cli: starting snapshot fails as expected
  ✅ sum-cli: solution passes
  ✅ tag-normalize: structure + snapshot
  ✅ tag-normalize: starting snapshot fails as expected
  ✅ tag-normalize: solution passes
  ✅ wordcount: structure + snapshot
  ✅ wordcount: starting snapshot fails as expected
  ✅ wordcount: solution passes
  fixtures: 3 tasks OK
  ```
  校验器还检查了：至少 3 个任务、字段/路径、ID 唯一、固定快照 SHA-256、
  grader/隐藏测试/solution/task.md 不在 agent 工作区、起始快照被评分器判失败、
  solution 覆盖后评分器通过。

- **AC2 [观察]**: ✅ `docs/benchmark-protocol.md` 覆盖：
  - 两种方法（单 agent / agent-foreman）；
  - 相同任务集、相同起始快照/提示约束、独立会话/工作区、顺序平衡、原始证据保存；
  - token 成本、wall-clock 起止点、隐藏测试缺陷漏出率分子/分母、人工介入次数。

  复核命中行（示例）：
  ```
  15:**方法 A · 单 agent**
  17:**方法 B · agent-foreman**
  35:两种方法使用完全相同的任务集、起始快照、任务说明和约束
  42:独立会话/工作区
  43:顺序平衡
  46:原始证据
  52:token 成本
  58:wall-clock
  66:分子：该次运行失败的隐藏测试数
  67:分母：该任务隐藏测试总数
  72:人工介入次数
  ```

- **AC3 [观察]**: ✅ 协议明确：
  - 本协议不授权任何 pilot；pilot 需人明确预算并另立计划；
  - token 只从会话日志/usage 读取；缺失记 `unavailable`，不估算；
  - 本任务不运行 agent、不采集真实用量、不写效果结论；
  - 原始日志不进仓库，提交前脱敏。

  复核命中行：
  ```
  4:本协议不产生“哪种方法更好”的结论；任何 pilot 必须由人另行批准预算并另立计划
  54:只从会话日志 / provider usage 读取；不估算
  56:缺失时记 unavailable；不填 0、不推算
  80:本协议不授权任何 pilot
  81:token 只能来自日志/usage；缺失就写 unavailable
  83:没有测量就不写“更便宜 / 更可靠 / 更好”的结论
  ```

- **AC4 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **改动**：新增 `benchmarks/check_fixtures.py`、3 个任务夹具、`docs/benchmark-protocol.md`；
  `.gitignore` 忽略 `benchmarks/runs/`
- **提交**：`981ba4f`
- **边界核对**：未运行真实 Codex/Claude 会话或 API；未采集真实订阅用量；
  未写 pilot 结果/成本优势/缺陷率结论；README 的 `[ ] 对照测量` 保持未勾选。
- **备注**：T11 审查 PASS（`c1ee32f`），AC5 仍待现场；T12 无依赖。
