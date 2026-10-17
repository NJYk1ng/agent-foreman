# STATUS — 让 Codex 在新项目中自动进入领导流程

> 工人：Claude Code (deepseek-flash[1m]) · 2026-10-17 · 提交：`233251e` + 本次改动

## T17 更新 Codex 全局规则以识别新项目 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ python3 - <<'PY'
  ... 四条分支 + 全部 lead 约束检查 ...
  PY
  Codex template branches and lead constraints: OK
  AC1_rc=0
  ```
  模板现在有四条分支：
  - 有 `.foreman/` → 领导；
  - 没有 `.foreman/` + 新项目/新需求（空目录）→ 领导：先建 `.foreman/`、问缺信息、写 PLAN，不直接实现；
  - 已有代码 + 只让改代码 → 照常；
  - 明确说「不用 foreman / 直接改」→ 照常。
  原有 lead 约束（不做实现、卡住两次、问人要审吗、`[现场]` 不判、不采信工人输出、PASS/BLOCK）全部保留。

- **AC2 [命令]**: ✅
  ```
  $ ./install.sh --force
  install_rc=0
  ...
  ✅ Claude Code 全局记忆：写入了 agent-foreman 角色说明
  ✅ Codex 全局记忆：写入了 agent-foreman 角色说明
  ✅ notify-lead 已是最新
  ...
  $ python3 - <<'PY'   # 对 ~/.codex/AGENTS.md 执行同一组断言
  installed Codex template branches and lead constraints: OK
  AC2_rc=0
  ```
  **注意：新规则只对新开的 Codex 会话生效；当前这个 Codex 会话仍是旧全局记忆，需要重启 Codex。**

- **AC3 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && \
      bash tests/test-install.sh && bash tests/test-notify-lead.sh
  foreman-check: 通过
  PASS=7 FAIL=0
  PASS=33 FAIL=0
  PASS=24 FAIL=0
  AC3_rc=0
  ```

- **AC4 [命令]**: ✅
  ```
  $ python3 scripts/check-links.py
  链接检查通过：28 个本地链接/锚点
  AC4_rc=0
  ```

- **AC5 [现场]**: ✅ 需求方于 2026-10-17 在本对话明确回复「AC5 通过」。
  依据：工人按需求方要求用 `codex exec` 新会话跑了四个场景，需求方确认结果符合：
  1. 空目录 + 需求：创建 `.foreman/`，读取 `tech-lead` / `agent-contract`，问脚本语言和验收方式，**未写代码**（`/tmp/af-test-new.tli70x`）。
  2. 空目录 + 完整规格：创建 `.foreman/PLAN.md`（T1 + 2 条 AC），**未写代码**（`/tmp/af-test-plan.KPBQur`）。
  3. 已有代码 + 只让改：`hello.sh` 的 `old` 改成 `new`，**没有** `.foreman/`（`/tmp/af-test-old.IuIRyB`）。
  4. 空目录 + 「不用 foreman」：直接写 `hello.sh`，**没有** `.foreman/`（`/tmp/af-test-off.w2KD0h`）。
  - 说明：以上是 `codex exec` 新会话，不是 live TUI；读取的是同一份已安装的 `~/.codex/AGENTS.md`。live TUI 需要重启 Codex 才会加载新规则；需求方已确认该行为。

- **改动**：`templates/global-codex.md` 增加四条分支；已用 `./install.sh --force` 更新 `~/.codex/AGENTS.md`（项目外，不进 git）。没有改 runtime、其他模板、skills、tests、README 或文档。
- **备注**：`install.sh --force` 同时把仓库 skills 重新装到两边并做了备份；这是安装器既有行为。当前 Claude 会话也不会重载全局记忆，但 Claude 侧的工人规则未改。
