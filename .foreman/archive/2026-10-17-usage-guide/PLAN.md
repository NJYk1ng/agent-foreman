# PLAN — 编写 agent-foreman 实际使用指南

> 领导：Codex · 2026-10-17 · 来源：需求方明确发起；基于当前 HEAD `c67b5a0`

## 背景与约束

- 需求方希望把真实安装和协作流程集中到新文件 `docs/usage.md`，让新项目能照着开始。
- 推荐路径是 `./install.sh --project <项目目录>`：它仍安装全局 skills / 角色记忆 / `notify-lead`，并额外创建 `.foreman/`、放入项目级 `AGENTS.md` 与 `CLAUDE.md`；只运行 `./install.sh` 则仅做全局安装，不提供项目级说明文件。
- 全局角色规则以项目根存在 `.foreman/` 为触发条件；只全局安装的新项目应在首次计划时明确 `$tech-lead`，并创建 `.foreman/`，或补跑 `--project` 获得项目级入口说明。
- 本轮唯一产品文档改动是 `docs/usage.md`；不改 README，因此不增加 README 链接，也不改代码、skills、templates 或行为。`.foreman/STATUS.md` 仅作为契约要求的执行汇报文件。
- 不写方法效果结论。`[现场]` 只能由人判；`notify-lead` 只把消息推给 Codex 会话，不等于审核或批准。

## 任务

### T15 编写安装与协作流程使用指南

- **目标**：新增一份能让用户按实际命令完成安装、开工、交接、审核、现场确认和归档的 `docs/usage.md`，且描述与仓库当前实现一致。
- **谁写**：工人
- **依赖**：需求方确认本计划后开始。
- **验收标准**：
  - AC1 [命令] `test -s docs/usage.md` → 退出码 0；文档包含全局安装与 `--project` 差异及原因、推荐 A（`--project`）、B（只全局）的补救方式、新项目第一句话 A/B 两例、完整协作流程、常见坑、常用命令等章节。
  - AC2 [命令] 执行下列内容检查 → `usage guide required items: OK`，并验证关键工作流顺序与必需章节：
    ```bash
    python3 - <<'PY'
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
    for heading in ['安装方式', '新项目第一句话', '完整流程', '常见坑', '常用命令']:
        assert heading in p, f'missing section: {heading}'
    print('usage guide required items: OK')
    PY
    ```
    → 检查覆盖顺序 `Codex PLAN → 人批准 → Claude /execute-plan → notify-lead → 人决定审核 → Codex cross-review → 人判 [现场] → 归档`；文档说明无 PLAN Claude 停止、lead/review skills 只在 Codex、[现场] 人判、`notify-lead` 只是叫醒。
  - AC3 [命令] `./install.sh --help | grep -F -- '--project' && bash scripts/notify-lead.sh --help | grep -F -- '--status'` → 两个选项均出现在各自帮助输出；文档中的安装、dry-run、项目路径、`notify-lead --status` 和通知命令与当前 CLI 用法一致。另 `rg -n '^name: (tech-lead|cross-review|execute-plan)$' skills/tech-lead/SKILL.md skills/cross-review/SKILL.md skills/execute-plan/SKILL.md` → 三个 skill 名均命中对应文件。
  - AC4 [命令] `./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh && python3 scripts/check-links.py && python3 benchmarks/check_fixtures.py` → 整条命令退出码 0；各测试通过，链接检查通过，夹具检查报告 `fixtures: 3 tasks OK`。
  - AC5 [命令] `git diff --check` → 退出码 0；`git diff -- README.md README.en.md install.sh scripts templates skills` → 无输出（这些文件和目录未被修改）。
- **边界**：唯一产品文件改动是新增 `docs/usage.md`；不改 README（包括不加链接）、代码、skills、templates、安装行为、测试、夹具或其他文档；不写效果结论。`.foreman/STATUS.md` 按协作契约记录执行结果。
