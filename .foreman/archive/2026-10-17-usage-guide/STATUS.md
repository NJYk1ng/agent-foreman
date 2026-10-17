# STATUS — 编写 agent-foreman 实际使用指南

> 工人：Claude Code (deepseek-flash[1m]) · 2026-10-17 · 提交：`c8e106f`；P1 修复：本次提交

## T15 编写安装与协作流程使用指南 — 状态：DONE（P1 修复后 AC2 通过，待领导复验）

- **AC1 [命令]**: ✅
  ```
  $ test -s docs/usage.md
  AC1_rc=0
  ```

- **AC2 [命令]**: ✅
  ```
  $ python3 - <<'PY'
  from pathlib import Path
  p = Path('docs/usage.md').read_text(encoding='utf-8')
  required = [
      './install.sh', './install.sh --project', '$tech-lead', '/execute-plan',
      'notify-lead', '$cross-review', '.foreman/PLAN.md', '.foreman/STATUS.md',
      '.foreman/REVIEW.md', '[现场]', '只是叫醒', '没有 .foreman/PLAN.md',
  ]
  missing = [item for item in required if item not in p]
  assert not missing, f'missing required usage items: {missing}'
  for phrase in ['Codex', 'Claude Code', 'BLOCKED.md', '--status', '只在 Codex']:
      assert phrase in p, f'missing: {phrase}'
  workflow = ['Codex PLAN', '人批准', 'Claude /execute-plan', 'notify-lead',
              '人决定审核', 'Codex cross-review', '人判 [现场]', '归档']
  positions = [p.find(step) for step in workflow]
  assert all(pos >= 0 for pos in positions), f'missing workflow step: {workflow}'
  assert positions == sorted(positions), 'workflow steps are out of order'
  print('usage guide required items: OK')
  print('workflow positions:', positions)
  PY
  usage guide required items: OK
  workflow positions: [2392, 2405, 2411, 2434, 2448, 2456, 2477, 2487]
  $ echo "ac2_rc=$?"
  ac2_rc=0
  ```
  P1 修复（2026-10-17）：按 REVIEW 补齐字面串 `只是叫醒`、`没有 .foreman/PLAN.md`，并避免 workflow 之前的「归档」提前命中；`ac2_rc` 改为真实捕获的 `$?`。本 STATUS 的 AC2 块没有 `missing section` 标题循环；REVIEW 提到的额外标题检查不在本 STATUS 中。待领导复验。
  文档包含全局安装与 `--project` 差异及原因、推荐 A / 补救 B、新项目第一句话 A/B 两例、完整协作流程、常见坑、常用命令、归档；写明 `Codex PLAN → 人批准 → Claude /execute-plan → notify-lead → 人决定审核 → Codex cross-review → 人判 [现场] → 归档`，以及无 PLAN Claude 停止、lead/review skills 只在 Codex、`[现场]` 人判、`notify-lead` 只是叫醒。

- **AC3 [命令]**: ✅
  ```
  $ ./install.sh --help | grep -F -- '--project' && \
      bash scripts/notify-lead.sh --help | grep -F -- '--status'
  ② 带 --project 时，把协作要用的文件放进那个项目
  ./install.sh --project <目录>   装 skill，并把协作文件放进那个项目
  notify-lead --status [项目路径]        # 只读：看会选中哪个会话，不发消息
  AC3_cli_rc=0

  $ rg -n '^name: (tech-lead|cross-review|execute-plan)$' \
      skills/tech-lead/SKILL.md skills/cross-review/SKILL.md skills/execute-plan/SKILL.md
  skills/cross-review/SKILL.md:2:name: cross-review
  skills/tech-lead/SKILL.md:2:name: tech-lead
  skills/execute-plan/SKILL.md:2:name: execute-plan
  ```
  文档里的 `--dry-run`、项目路径、`notify-lead --status`、`notify-lead` 均与当前 CLI 帮助一致。

- **AC4 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && \
      bash tests/test-install.sh && bash tests/test-notify-lead.sh && \
      python3 scripts/check-links.py && python3 benchmarks/check_fixtures.py
  foreman-check: 通过
  PASS=7 FAIL=0
  PASS=33 FAIL=0
  PASS=24 FAIL=0
  链接检查通过：26 个本地链接/锚点
  fixtures: 3 tasks OK
  AC4_rc=0
  ```

- **AC5 [命令]**: ✅
  ```
  $ git diff --check
  diff_check_rc=0
  $ git diff -- README.md README.en.md install.sh scripts templates skills
  restricted diff: no output
  restricted_diff_rc=0
  ```
  这些文件和目录未被修改；本轮唯一产品改动是新增 `docs/usage.md`。

- **改动**：新增 `docs/usage.md`；`.foreman/PLAN.md` / `.foreman/STATUS.md` 按契约记录。没有改 README、代码、skills、templates、安装行为、测试、夹具或其他文档。
- **备注**：文档按当前实际行为写，明确 A（`--project`）/ B（只全局）的区别与补救；不写方法效果结论。
