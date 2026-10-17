# PLAN — 消除 agent-foreman 的协作矛盾并补齐安全与自动检查

> 领导：Codex · 2026-10-17 · 来源：需求方授权的新计划；Claude 只读审查结论及优先级

## 背景与约束

仓库文档对领导/工人的职责、通知时机和任务执行方式有互相冲突的说法；安装器和 `notify-lead` 也有可复现的安全与选会话问题。
本轮按 P1 优先修复指令矛盾、安装器和会话选择，再处理模板护栏、契约/文档漂移、自动检查和用户文档。
每个任务单独提交一次；按 T1→T7 顺序执行，后续任务可在前置任务完成后各自提交。
领导只负责计划与审核，所有实现任务均分配给工人；计划中不再承诺由领导亲自写代码。
旧计划三件套已移到 `.foreman/archive/2026-10-17-self-review/`，不得恢复到 `.foreman/` 根目录。

## 任务

### T1 统一角色边界、通知流程和执行路径

- **目标**：全仓库只有一套无冲突的领导/工人职责与完工通知流程，所有实现任务均能由工人执行。
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `rg -n '不要自动去调领导|不要自己去叫领导' skills/execute-plan/SKILL.md templates/global-claude.md templates/AGENTS.md` → 不再出现相互冲突的指令；工人完成汇报后的通知行为在 `execute-plan`、Claude 全局模板和项目模板中一致。
  - AC2 [观察] 逐项核对 `skills/agent-contract/SKILL.md`、`skills/tech-lead/SKILL.md`、`docs/contract.md`、`README.md`、`README.en.md`、`templates/AGENTS.md`、`templates/global-claude.md`、`templates/global-codex.md` 中的角色规则 → 一致表述领导负责规划/审核、工人实现；删除无法执行的“领导亲自写代码”承诺，并给困难任务提供可由工人执行的分配/升级路径。将逐项核对的命中行写入 `STATUS.md`。
  - AC3 [命令] `git diff --check` → 退出码 0。
- **边界**：不改变“工人不得自行触发领导审核、阻塞答复须经人授权”的额度闸门；不引入 `LEAD_STATUS.md` 或新的代码交接机制。

### T2 修复安装器卸载、覆盖备份和冲突提示

- **目标**：卸载和强制安装不会静默丢失用户数据，项目文件冲突提示可以直接执行。
- **谁写**：工人
- **依赖**：T1
- **验收标准**：
  - AC1 [命令] 使用临时 HOME 安装并运行 `install.sh --uninstall` 的回归用例 → 当全局文件有开始标记但缺结束标记时，命令失败并保持目标文件逐字节不变。
  - AC2 [命令] 使用临时 HOME 预置与仓库版本不同的同名 skill，分别运行默认安装和 `--force` 安装的回归用例 → 默认安装保留用户版本；`--force` 覆盖前生成可恢复的备份，备份内容与原版本一致。
  - AC3 [命令] 在临时项目中预置冲突的 `AGENTS.md` 后运行 `install.sh --project <临时项目>` → 冲突提示给出可用的合并指引，不再要求文件自引用 `@AGENTS.md`。
  - AC4 [命令] `bash -n install.sh` → 退出码 0。
- **边界**：不得降低默认安装对不同内容文件的保护；卸载时不得删除标记段之外的内容。

### T3 让 notify-lead 明确选择正确的交互会话

- **目标**：`notify-lead` 只会通知目标项目的交互式 Codex 会话，且会话选择和失败原因可明确控制、诊断。
- **谁写**：工人
- **依赖**：T2
- **验收标准**：
  - AC1 [命令] `bash tests/test-notify-lead.sh` → 覆盖含多个同项目 `codex_exec`/subagent 与交互会话的数据库夹具，并断言默认只选交互会话；全部用例通过。
  - AC2 [命令] `bash tests/test-notify-lead.sh` → 覆盖 `--thread <id>` 显式选会话、项目路径含符号链接时按真实路径匹配、无会话时的非零退出码及可操作错误信息；全部用例通过。
  - AC3 [命令] `bash tests/test-notify-lead.sh` → 覆盖 Codex 数据库 schema 不兼容、数据库缺失和 `python3` 缺失；每种情况均以非零状态退出并说明具体原因，不误报为“没找到会话”。
  - AC4 [命令] `bash -n scripts/notify-lead.sh` → 退出码 0。
- **边界**：不得向非交互式 `codex_exec` 或 subagent 会话发送消息；不得在未指定 `--thread` 时跨项目选择会话；数据库只读访问。

### T4 为全局和项目模板增加无计划时停工护栏

- **目标**：工人启动后发现没有 `.foreman/PLAN.md` 时，会停止实现并报告给人。
- **谁写**：工人
- **依赖**：T1
- **验收标准**：
  - AC1 [命令] `rg -n '没有 .foreman/PLAN.md.*停止|没有计划.*停止.*实现' templates/AGENTS.md templates/global-claude.md skills/execute-plan/SKILL.md` → 三个工人入口都包含明确的停工和报告指引。
  - AC2 [命令] `rg -n 'PLAN.md.*不存在|没有 .foreman/PLAN.md' templates/AGENTS.md templates/global-claude.md skills/execute-plan/SKILL.md` → 指引明确要求先确认计划文件存在，不得从需求描述自行开工。
  - AC3 [命令] `git diff --check` → 退出码 0。
- **边界**：不改 Codex 领导收到需求后生成计划的入口规则；不删除本轮已归档的旧审查记录。

### T5 对齐契约、技能、测量数据和文档链接

- **目标**：契约、技能、架构文档和中英文 README 对同一流程使用一致术语、状态定义和可达链接。
- **谁写**：工人
- **依赖**：T1、T4
- **验收标准**：
  - AC1 [命令] `rg -n 'CC\|Codex|CC \| Codex|⏸|钩子（期二）|7\.3k|49k|提交：本次提交' docs/contract.md skills README.md README.en.md docs/architecture.md` → 不再命中已确认的旧术语、旧状态符号、旧阶段描述、过时测量值或非 SHA 提交示例。
  - AC2 [观察] 对照 `README.md`、`README.en.md` 和 `docs/what-it-is-for.html` 中修改过的本地链接与目标标题/文件 → 每条链接均可到达；在 `STATUS.md` 列出核对过的链接及目标。
  - AC3 [观察] 对照 `skills/agent-contract/SKILL.md` 与 `docs/contract.md` → 角色名称、五种任务状态、`[现场]` 判定规则及领导不得判现场通过的规则逐项一致；检查结果写入工人 `STATUS.md` 的可复核条目。
- **边界**：不改变本轮 T1 确立的角色边界和额度闸门；不改与这些修复无关的产品定位或项目历史描述。

### T6 增加 foreman check、shell 回归测试和 CI

- **目标**：常见契约/模板/安装器/通知脚本回归可由单条本地命令和 CI 自动发现。
- **谁写**：工人
- **依赖**：T2、T3、T4、T5
- **验收标准**：
  - AC1 [命令] `./scripts/foreman-check.sh` → 检查 `.foreman/PLAN.md` 存在且非空、计划任务必填字段、任务编号唯一、模板停工护栏及脚本语法；通过时退出码 0，故意破坏任一检查项时退出码非 0 并指出文件/检查项。
  - AC2 [命令] `bash tests/test-install.sh` → 在隔离临时 HOME 中覆盖默认安装、用户 skill 保护、`--force` 备份、损坏标记卸载和项目文件冲突；全部用例通过，退出时清理临时目录。
  - AC3 [命令] `bash tests/test-notify-lead.sh` → T3 的所有会话选择与错误路径回归通过。
  - AC4 [命令] `./scripts/foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh` → 退出码 0；CI 工作流执行同一组命令并在失败时标红。
- **边界**：仅使用 Bash/Python 标准库和仓库现有依赖；不得读写真实用户 HOME、Codex 会话库或系统级安装目录。

### T7 整理快速入口、HTML/英文说明和通知状态查看

- **目标**：新用户能从中英文 README 的 TL;DR 找到正确的安装/开工步骤，且可在不发送通知的情况下查看 `notify-lead` 将选中的会话。
- **谁写**：工人
- **依赖**：T3、T5、T6
- **验收标准**：
  - AC1 [命令] `rg -n 'TL;DR|快速开始|notify-lead --status|foreman-check' README.md README.en.md docs/what-it-is-for.html` → 中英文 README 和项目 HTML 说明均有对应的快速入口、检查命令和功能说明。
  - AC2 [命令] `notify-lead --status <项目路径>` 的隔离夹具用例 → 输出解析后的项目根和将被选中的交互会话 ID，不调用 `codex queue`；无候选会话时返回非零并输出可操作原因。
  - AC3 [命令] 本地 Markdown/HTML 链接检查 → `README.md`、`README.en.md`、`docs/what-it-is-for.html` 中新增或修改的本地链接均可解析。
  - AC4 [命令] `git diff --check` → 退出码 0。
- **边界**：`--status` 只能只读诊断，不得创建会话、排队消息或修改项目文件；不重写与本计划无关的 README 内容。
