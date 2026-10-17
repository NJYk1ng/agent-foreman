# PLAN — README 使用指南入口与本地 v1.0.0 标签

> 领导：Codex · 2026-10-17 · 来源：需求方明确发起；T13–T15 审核已提交于 `896c6d3`

## 背景与约束

- T13 / T14 / T15 的归档 REVIEW 已提交在 `896c6d3`；本计划提交后，后续 README 提交与 tag 应包含该审核记录。
- 只在 `README.md` 与 `README.en.md` 各自 TL;DR 增加一行 `docs/usage.md` 链接；其余 README 内容不动。
- README 两文件改动作为一个提交；该提交之后创建指向此提交的 annotated tag `v1.0.0`。只创建本地 tag，不 push、不发 release；如果 tag 已存在，不覆盖，停止并报告。
- 本轮不包含正式对照测量；任何正式测量都需另批预算并另立计划。不写效果结论。

## 任务

### T16 在 README TL;DR 增加使用指南入口并创建本地 tag

- **目标**：两份 README 的 TL;DR 各有一个指向 `docs/usage.md` 的入口；README 改动提交后，创建一个指向该提交的 annotated tag `v1.0.0`。
- **谁写**：工人
- **依赖**：需求方确认本计划后开始；开始前确认 `v1.0.0` 尚不存在。已提交的审核基线 `896c6d3` 必须是 README 提交的祖先。
- **验收标准**：
  - AC1 [命令] 在两份 README 各自 `## TL;DR` 到下一个分隔线之间新增恰好一行 Markdown 链接，目标为 `docs/usage.md`。执行以下检查 → `README TL;DR usage links: 2 files OK`：
    ```bash
    python3 - <<'PY'
    from pathlib import Path
    for name in ('README.md', 'README.en.md'):
        text = Path(name).read_text(encoding='utf-8')
        section = text.split('## TL;DR', 1)[1].split('\n---', 1)[0]
        links = [line for line in section.splitlines()
                 if 'docs/usage.md' in line]
        assert len(links) == 1, (name, links)
        assert '](' in links[0] and '(docs/usage.md)' in links[0], (name, links[0])
    print('README TL;DR usage links: 2 files OK')
    PY
    ```
  - AC2 [命令] `python3 scripts/check-links.py` → 链接检查通过（包含新加的两个本地链接）。
  - AC3 [命令] `./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh` → 整条命令退出码 0，各回归套件通过。
  - AC4 [命令] README 提交前 `git diff --check` → 退出码 0；`git diff --name-only` → 仅 `README.md` 与 `README.en.md`；两文件改动作为单独一个提交，不夹带其他文件。
  - AC5 [命令] README 提交后创建 annotated tag `v1.0.0`，并执行：
    ```bash
    test "$(git cat-file -t v1.0.0)" = tag
    test "$(git rev-parse 'v1.0.0^{}')" = "$(git rev-parse HEAD)"
    git merge-base --is-ancestor 896c6d3 "$(git rev-parse 'v1.0.0^{}')"
    ```
    → 全部退出码 0；tag 解引用指向 README 提交，且包含审核提交 `896c6d3`。
- **边界**：只改 `README.md` / `README.en.md` 的 TL;DR 链接行；只创建本地 annotated tag `v1.0.0`。不改 README 其他内容、代码、skills、templates、tests、fixtures 或 `docs/usage.md`；不 push、不发布 release、不覆盖既有 tag；不开展正式对照测量或写效果结论。
