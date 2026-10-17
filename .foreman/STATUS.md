# STATUS — 固定 CI 环境并准备对照测量

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：ff0f47c（T11）、981ba4f（T12）、c9c17ec（T12 P2 修复）；本 STATUS 随后单独提交

## T11 固定 CI runner 与 checkout 运行时 — 状态：DONE

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

- **AC5 [现场]**: ✅ 需求方已验（2026-10-17）—— GitHub Actions run
  https://github.com/NJYk1ng/agent-foreman/actions/runs/39011559456
  - head：`c55ef98`（包含 T11 的 `ff0f47c`）
  - job `test`：所有步骤 success
  - runner labels：`["ubuntu-24.04"]`
  - `annotations_count`：0（Node.js 20 警告已消失）
  - 回归日志：`foreman-check: 通过`、`PASS=33`、`PASS=24`、`PASS=7`、
    `链接检查通过：26 个本地链接/锚点`

- **改动**：`.github/workflows/ci.yml`
- **提交**：`ff0f47c`
- **边界核对**：实现只改 `.github/workflows/ci.yml`；push 由需求方授权后执行，用于 AC5 现场验证。
- **备注**：AC5 由需求方于 2026-10-17 判通过；T11 收口为 `DONE`。

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

### T12 P2 修复 — 状态：DONE

- **隐藏测试副本**：新增 `metadata.visible_files`；校验器要求 workspace 文件集合与清单完全一致。
  负向演示（临时副本中把 `grader/test_sum.sh` 复制成 `workspace/leaked-test.sh`，
  并同步快照哈希）：
  ```
  ❌ sum-cli: workspace files do not match visible_files (actual=['leaked-test.sh', 'sum.sh'], expected=['sum.sh'])
  fixtures: FAILED
  ```
- **token cache 归一化**：协议 4.1 明确 cache 是 input 的细分、不重复加；
  有 canonical total 用它，否则 `input + output`；跨 provider 用同一归一化定义。
- **回归**：`python3 benchmarks/check_fixtures.py` → `fixtures: 3 tasks OK`。
- **提交**：`c9c17ec`
