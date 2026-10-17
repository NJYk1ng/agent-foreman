# PLAN — 收口安装器、CI 与文档边界

> 领导：Codex · 2026-10-17 · 来源：人明确发起的新计划

## 背景与约束

T1–T7 已完成并归档；本计划只处理剩余的安装器保护、链接检查 CI 和文档准确性。
本地 `master` 领先 `origin/master` 的提交以及尚未在 GitHub 运行的 CI 属于人的部署动作，不纳入实现任务。
对照测量、push / 重启、版本 tag / changelog / macOS CI 均不属于本轮范围。
所有实现由工人完成；任一任务卡住两次，工人写 `.foreman/BLOCKED.md`，由人决定是否请领导给方向或改计划。

## 任务

### T8 安装器保护已有 notify-lead

- **目标**：安装时不会静默丢失用户已有的 `notify-lead`，强制覆盖前会保存可恢复的原始内容。
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] 在 `tests/test-install.sh` 新增临时 HOME 用例，预置内容与仓库版本不同的 `~/.local/bin/notify-lead`：普通安装后文件内容与预置内容完全一致，并输出保留文件的明确提示；同一夹具执行 `--force` 后脚本被仓库版本覆盖，且生成的 `notify-lead.bak-*` 备份内容与预置内容完全一致。测试不得读写真实 HOME。
  - AC2 [命令] `bash -n install.sh` → 退出码 0。
  - AC3 [命令] `bash tests/test-install.sh` → 全部断言通过，输出 `FAIL=0`。
- **边界**：不改 uninstall 的“内容不同就留着”逻辑；不碰真实 HOME；不改与 `notify-lead` 安装保护无关的安装行为。

### T9 将文档链接检查纳入 CI

- **目标**：CI 和本地回归都能因 Markdown / HTML 本地链接或锚点失效而失败。
- **谁写**：工人
- **依赖**：T8
- **验收标准**：
  - AC1 [命令] `rg -n 'python3 scripts/check-links\.py' .github/workflows/ci.yml` → 命中 CI 执行步骤。
  - AC2 [命令] `python3 scripts/check-links.py` → `链接检查通过：26 个本地链接/锚点`。
  - AC3 [命令] `./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh && python3 scripts/check-links.py` → 退出码 0；四个既有回归命令保留，新增链接检查。
  - AC4 [命令] `git diff --check` → 退出码 0。
- **边界**：不删除、替换或重写现有四个回归命令；本任务只改 CI 和必要的链接检查调用，不改链接检查器的校验范围。

### T10 修正文档中的过时和不准确描述

- **目标**：中英文 README 与 HTML 说明准确呈现依赖、卸载保证、项目状态和文档语言范围，并能从 README 找到两页说明文档。
- **谁写**：工人
- **依赖**：T9
- **验收标准**：
  - AC1 [命令] `rg -n '零依赖|zero dependencies|逐字节还原|byte-for-byte' README.md README.en.md` → 无输出、退出码 1；README 不再声称零依赖或卸载逐字节还原。用准确措辞说明无额外包依赖 / 无常驻服务；卸载描述须与实际换行行为一致，或由回归测试证明逐字节还原。
  - AC2 [命令] `rg -n '期二（钩子）未做' docs/showcase.html` → 无输出、退出码 1；展示页不再把已评估并放弃的钩子描述成待做阶段。
  - AC3 [命令] `for f in README.md README.en.md; do rg -q 'docs/showcase\.html' "$f" && rg -q 'docs/what-it-is-for\.html' "$f" || exit 1; done` → 两个 README 都有指向两页 HTML 说明的链接；README 的项目状态清单列出 `foreman-check`、测试、CI 和 `--status`；英文 README 明确说明详细规范目前只有中文，或提供完整英文翻译。
  - AC4 [命令] `python3 scripts/check-links.py` → 链接检查通过，退出码 0（链接数随新增链接变化）。
  - AC5 [命令] `git diff --check` → 退出码 0。
- **边界**：不改 T1 确立的角色边界与额度闸门；不重写与本任务列出的准确性问题无关的产品定位描述。
