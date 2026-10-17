# 实际使用指南

> 面向「装好之后到底怎么用」。安装、开工、交接、审核、现场确认、收尾，全部按当前实现写。

## 一、先选安装方式

| 方式 | 命令 | 适合 |
|---|---|---|
| 全局安装 | `./install.sh` | 让这台机器具备 skill；Codex 只在项目里有 `.foreman/` 时才当领导 |
| 项目安装（推荐） | `./install.sh --project /path/to/项目` | 新项目一打开，Codex 就知道自己是领导 |

`./install.sh --project` 会做三件事：

1. 把 skills 装到 `~/.claude/skills` / `~/.codex/skills`（已装则跳过）；
2. 写全局角色记忆（`~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md`）；
3. 在项目里创建 `.foreman/`，写入项目级 `AGENTS.md` 和 `CLAUDE.md`（后者是 `@AGENTS.md` 的转发）。

项目级 `AGENTS.md` 直接写「Codex = 领导，Claude Code = 工人」，所以 Codex 一进项目就能读到。`AGENTS.md` 是单一事实来源，`CLAUDE.md` 不要另写一份不同内容。

### 为什么分 A / B

- **A：项目安装** —— `./install.sh --project`。创建 `.foreman/` 和项目角色说明，Codex 开场就知道自己是领导。**推荐。**
- **B：只做全局安装** —— 新项目没有 `.foreman/`，全局规则会「忽略领导段，照常干活」；Codex 默认是普通编码模式。

这样分是为了避免全局劫持：Codex 还用于很多不用 agent-foreman 的项目，不能一装就永远当领导。`.foreman/` 是「这个项目启用协作」的开关；`--project` 帮你把开关和门牌一起放好。

如果只做了 B，有两种补救：

```bash
# 方式 1：补一次项目安装
./install.sh --project .

# 方式 2：只建开关（项目里没有角色说明文件）
mkdir .foreman
```

或者在首次需求时显式调用 Codex 侧 skill：

```text
$tech-lead <需求>
```

## 二、新项目的第一句话

第一句在 **Codex** 里说，位置是**项目根目录**。

### A：用 `--project` 初始化过

直接用自然语言说需求，不需要 `$tech-lead`：

```text
我们要做机器狗 3D 跨楼层导航。
先别写代码，按计划流程拆需求；缺的信息先问我，再写 .foreman/PLAN.md。
```

Codex 读到项目 `AGENTS.md`，会用 `tech-lead` skill 写 `.foreman/PLAN.md`。

### B：只做了全局安装

新项目没有 `.foreman/`，Codex 默认普通编码。用下面任一种方式进入协作：

```text
# 方式 1：显式调用 lead skill
$tech-lead 我们要做机器狗 3D 跨楼层导航。先别写代码，缺的信息先问我，再写 PLAN。
```

```bash
# 方式 2：先建开关，再说需求
mkdir .foreman
```

**不要**在 Claude Code 里说 `$tech-lead` —— Claude 侧没有这个 skill。

## 三、角色与文件

| 角色 | 谁 | 职责 |
|---|---|---|
| 领导 | Codex | 拆需求、写 `PLAN.md`、审 `REVIEW.md`；不写实现 |
| 工人 | Claude Code | 按 `PLAN.md` 实现、自证、写 `STATUS.md`；不重新规划 |
| 需求方 | 人 | 给需求、批计划/预算、决定审不审、做 `[现场]` 验证 |

`.foreman/` 里的文件：

| 文件 | 谁写 | 作用 |
|---|---|---|
| `.foreman/PLAN.md` | 领导 | 任务、`谁写`、依赖、验收标准、边界 |
| `.foreman/STATUS.md` | 工人 | 逐条自证的真实输出和状态 |
| `.foreman/BLOCKED.md` | 工人 | 卡住两次后的求助；必须含「已试过」 |
| `.foreman/REVIEW.md` | 领导 | 审核结论：`PASS` 或 `BLOCK` |

- 一个 `.foreman/` 对应一个工作单元（一个 PR 的量级）；计划做完就收进 archive。
- 状态只有五个：`TODO` / `WIP` / `BLOCKED` / `UNVERIFIED` / `DONE`。
- 验收标准只有三级：`[命令]` / `[观察]` / `[现场]`。
- **`[现场]` 只能由人判**；工人只能写「⏳ 待现场验证」+ 复现步骤。**`UNVERIFIED` ≠ `DONE`。**
- **没有 .foreman/PLAN.md 时，Claude 停止，不得从需求描述自行开工。**
- lead/review skills 只在 Codex 侧：`$tech-lead`、`$cross-review`；工人侧用 `/execute-plan`；`agent-contract` 两端共用。

## 四、完整流程

```text
Codex PLAN → 人批准 → Claude /execute-plan → notify-lead → 人决定审核 → Codex cross-review → 人判 [现场] → 归档
```

1. **Codex 出计划**：`$tech-lead`（或项目 `AGENTS.md` 已让 Codex 进入领导角色）写 `.foreman/PLAN.md`。缺信息先问人。
2. **人批准**：审任务是否一个工作单元、AC 是否可证、`[现场]` 是否写清「谁 / 在哪 / 做什么 / 什么算通过」；确认预算/范围。
3. **Claude 执行**：`/execute-plan`。实现、跑 `[命令]`、核对 `[观察]`，写 `.foreman/STATUS.md`；`[现场]` 只写 ⏳ 和复现步骤。
4. **叫醒领导**：Claude 跑 `notify-lead`。它**只是叫醒** Codex 把消息推进会话，不等于审核或批准。
5. **人决定审不审**：审核花 Codex 额度，必须由人决定。
6. **Codex 审核**：`$cross-review`。逐条重跑 `[命令]`、看 diff，写 `.foreman/REVIEW.md`；`[现场]` 只能写「无法判定」。
7. **打回或放行**：`BLOCK` 时 Claude 按 REVIEW 修、更新 `STATUS.md`；`PASS` 后进入现场。
8. **人做 `[现场]`**：按 PLAN 的步骤在真实环境验证；通过后任务才算 `DONE`。
9. **归档**：见第六节。

## 五、常见坑

- **只做了全局安装，却以为 Codex 在新项目会自动当领导**：不会。用 `--project`、`mkdir .foreman`，或 `$tech-lead`。
- **在 Claude Code 里敲 `$tech-lead`**：Claude 只认 `/execute-plan`；`$tech-lead` / `$cross-review` 是 Codex 侧。
- **没有 PLAN 就让 Claude 开工**：Claude 会停，并报告「这里没有计划，需要领导先写 PLAN」。
- **把 `[现场]` 或 `UNVERIFIED` 写成 `DONE`**：工人不能替人判现场；只有人验证过才能标通过。
- **把 `notify-lead` 当审核**：它只是叫醒；真正花额度的是 `$cross-review`，且要人发起。
- **审核时采信工人贴的输出**：领导要自己重跑命令。文本上分不出真跑还是凭记忆写的。
- **改已派发的 AC 不重新声明未完成**：改 AC = 移动靶；必须先留痕，并把任务重新声明为未完成。
- **把隐藏测试/grader 放进工人工作区**：不要提供给 agent；评分在工作区外跑。
- **提前勾选 `README.md` 的 `[ ] 对照测量`**：只有真实测量并记录后才能勾选；dry run 不算。

## 六、归档

归档不是删除，是把已完成的计划从 `.foreman/` 根目录**移进** `.foreman/archive/<日期-名字>/`；git 记为 rename，历史保留。

```bash
mkdir -p .foreman/archive/2026-10-17-<名字>
git mv .foreman/PLAN.md .foreman/STATUS.md .foreman/REVIEW.md \
       .foreman/archive/2026-10-17-<名字>/
```

如果没有 `REVIEW.md`，就只移存在的那几个。归档后 `.foreman/` 根目录没有活跃计划，`foreman-check` 会跳过计划检查；下一块工作单元由领导重新写 `.foreman/PLAN.md`。

## 七、常用命令

```bash
# 安装
./install.sh
./install.sh --project /path/to/项目
./install.sh --dry-run
./install.sh --force
./install.sh --uninstall

# 叫醒领导（只叫醒，不审核）
notify-lead
notify-lead --status
notify-lead --thread <session-id>

# 自检
./scripts/foreman-check.sh
bash tests/test-install.sh
bash tests/test-notify-lead.sh
bash tests/test-foreman-check.sh
python3 scripts/check-links.py
python3 benchmarks/check_fixtures.py
```

`notify-lead --status` 是只读诊断：打印会被叫醒的项目和 Codex thread，不发消息。`notify-lead` 从当前目录往上找 `.foreman/`，在项目里任意位置都能跑。

## 八、一句话

**Codex 拆需求、写 AC、审；Claude 实现、自证；人批计划、批审核、做 `[现场]` 验证。`notify-lead` 只是叫醒，不是审核。**
