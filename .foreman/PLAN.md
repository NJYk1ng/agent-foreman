# PLAN — 让 Codex 在新项目中自动进入领导流程

> 领导：Codex · 2026-10-17 · 来源：需求方明确要求修改 Codex 全局规则

## 背景与约束

- 当前 `templates/global-codex.md` 只在项目根已有 `.foreman/` 时启用领导规则；新项目的空目录会被要求照常工作。
- 需求方确认：新项目/新需求应默认进入计划流程；已有代码的普通改动和用户明确要求绕过 foreman 的任务仍照常处理。
- 通过更新模板及 `./install.sh --force` 更新 `~/.codex/AGENTS.md`；新规则只对新开的 Codex 会话生效，完成后提醒人重启 Codex。
- 不改 runtime、安装器逻辑或其他模板；不写效果结论。

## 任务

### T17 更新 Codex 全局规则以识别新项目

- **目标**：让 Codex 在新项目空目录中收到新项目需求时先启用 foreman、创建 `.foreman/`、补齐缺失信息并写计划，不直接实现；同时保留现有代码改动及明确绕过 foreman 的常规行为。
- **谁写**：工人
- **依赖**：需求方确认本计划后开始。
- **验收标准**：
  - AC1 [命令] 模板分支与约束检查：
    ```bash
    python3 - <<'PY'
    from pathlib import Path
    p = Path('templates/global-codex.md').read_text(encoding='utf-8')
    branches = {
        'existing foreman': ['有 `.foreman/`', '领导'],
        'new project without foreman': ['没有 `.foreman/`', '新项目', '空目录', '.foreman/', '必要时', '复制', 'AGENTS.md', 'CLAUDE.md', '缺失信息', '.foreman/PLAN.md', '不直接实现'],
        'existing code change': ['已有代码', '只让改代码', '照常'],
        'explicit opt-out': ['不用 foreman', '直接改', '照常'],
    }
    for name, terms in branches.items():
        missing = [term for term in terms if term not in p]
        assert not missing, f'{name}: missing {missing}'
    constraints = ['不做实现', '卡住两次', '要我现在审吗？', '[现场]', '不采信工人贴的命令输出', 'BLOCK', 'PASS']
    missing = [term for term in constraints if term not in p]
    assert not missing, f'lead constraints missing: {missing}'
    print('Codex template branches and lead constraints: OK')
    PY
    ```
    → 输出 `Codex template branches and lead constraints: OK`；新项目分支必须要求先创建 `.foreman/`、必要时复制项目 `AGENTS.md` / `CLAUDE.md`，先问缺失信息再写 PLAN，且不得直接实现。已有 `.foreman/` 分支保留原规则。
  - AC2 [命令] `./install.sh --force` → 退出码 0；随后检查 `~/.codex/AGENTS.md` 的 agent-foreman 管理段包含 AC1 的四种分支及全部领导约束（可用 AC1 检查对已安装文件执行同一组断言）。STATUS 明确提醒：更新只对新会话生效，需重启 Codex。
  - AC3 [命令] `./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh` → 整条命令退出码 0，所有测试通过。
  - AC4 [命令] `python3 scripts/check-links.py` → 本地链接与锚点检查通过。
  - AC5 [现场] 需求方 / 重启 Codex 后的新会话，分别在空测试目录描述一个信息不全的新项目、在含代码的临时项目提出普通代码修改、在空测试目录明确说「不用 foreman / 直接改」；通过标准：第一种先创建 `.foreman/` 并询问缺失信息；需求方补充信息后，Codex 写出 PLAN 且没有实现代码；后两种照常处理，不因全局规则强制创建 `.foreman/` 或 PLAN。该项只能由需求方判断，工人记录复现步骤和结果，不得自判通过。
- **边界**：只改 `templates/global-codex.md`；只有若现有自动检查确实无法覆盖模板分支时，才允许补充 `tests/test-foreman-check.sh` 中的相关检查。不改 `install.sh`、runtime、其他 templates / skills / tests、README 或文档；不写效果结论。卡住两次 → 写 `.foreman/BLOCKED.md` → 由人决定是否请领导给方向/改计划。
