# STATUS — 固定 CI 环境并准备对照测量

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：ff0f47c（T11 实现；本 STATUS 随后单独提交）

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
