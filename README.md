# agent-foreman

**领导负责思考，工人负责干活。**

[English](README.en.md) · 简体中文

一套 agent skill：把 **Codex** 变成技术负责人 —— 拆任务、审代码、排障；把 **Claude Code** 变成干活的队伍，背后接哪个模型端点由你定。

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Harnesses](https://img.shields.io/badge/harness-Claude%20Code%20%C2%B7%20Codex-orange.svg)](#环境要求)
[![Status](https://img.shields.io/badge/status-pre--alpha-red.svg)](#项目状态)

---

## 为什么需要它

### 壳（harness）和模型供应商是可以拆开的

Claude Code 的价值大半在它的**壳**上 —— skill、hook、子 agent、MCP、终端交互。而这个壳接得上任何 Anthropic 兼容端点。**你可以留着壳，换掉后面的模型。**

这个解耦之所以重要，是因为各家模型供应商在两个维度上**并不等价**：**价格**和**可用性**。

- **价格。** 前沿订阅制模型按 token 折算下来，可能是一个便宜 API 端点的 10~50 倍。而 agent 的长会话恰好是最贵的那种用法 —— 见下。
- **可用性。** 在部分司法辖区，各家供应商对账号条款的执行严格程度并不一致。如果你的整套工作流焊死在单一供应商上，那么**这家供应商的可用性就是你的可用性**。跑不起来的工作流，价值等于零。

### 长会话的成本是平方级的，而订阅的上限是额度

两个壳在 HTTP 上都是**无状态**的：每一轮都要把整个会话重发一遍。所以一个会话的总消耗随长度**平方**增长。在我们实测的一个真实会话里，`cache_read` 占了全部计费 token 的 **99%** —— 成本的大头是"把已经发过的上下文再发一次"。

与此同时，订阅制套餐卡的是**额度**（滚动窗口 + 周上限），不是钱。额度一光，工作流当场停摆 —— 而且通常停在任务做到一半的时候。

### 所以：按「需要什么」分工，而不是按「谁更聪明」

| | 需要 | 该配什么 |
|---|---|---|
| **领导** | 判断力，以及**小**上下文 | 最稳、最强的**订阅** |
| **工人** | 耐力，以及**大**上下文 | 最便宜的**端点** |

这也正是真实工程团队的样子。一个好的技术负责人并不写大部分代码 —— 他定方向、拆任务、审结果，然后**亲自写那 10% 真正难的部分**。

**agent-foreman** 把这套结构装进两个 agent。

---

## 它怎么工作

```
                          你
                           │  需求
                           ▼
              ┌────────────────────────────┐
              │  领导  ·  Codex            │
              │  拆任务 · 审代码 · 排障     │
              │  小上下文，额度安全          │
              └─────────────┬──────────────┘
                            │  .foreman/PLAN.md    做什么，含验收标准
                            │  .foreman/REVIEW.md  哪里错了，按严重度分级
                            ▼
              ┌────────────────────────────┐
              │  工人  ·  Claude Code      │
              │  实现 · 自测 · 汇报         │
              │  便宜端点，长上下文          │
              └─────────────┬──────────────┘
                            │  .foreman/STATUS.md  证据，逐条对应验收标准
                            │  .foreman/BLOCKED.md 已试过什么，需要什么
                            └──────────────►  回到领导
```

两个 agent **不共享会话，共享文件** —— 一个双方都能读写的目录。整个协议就这么简单，而且是**故意**做这么土的：能 `cat` 出来的协议，才是能调试的协议。

**为什么不让两个 agent 实时聊天？** 因为两个都是**回合制**的，不是常驻服务。一个 agent 在跑某一轮的时候，它并不在监听。所谓"实时"最多只能是"下一个回合边界"—— 而**每一条塞进上下文的消息，都会在之后每一轮被重新发送一次**。两个 agent 高频聊天，成本涨得比产出快。真实团队是在**交接点**同步的，不是持续对话。

---

## 相关项目

**[sno-station-skills](https://github.com/sno-ai/sno-station-skills)**（Apache-2.0）覆盖了相邻的领域，而且做得不错：跨供应商评审、带"完成定义"的任务单、额度耗尽时自动交接。**如果你手上是两个付费订阅** —— Claude Code 和 Codex 都买了 —— 先去读它，它可能就是你想要的东西。

agent-foreman 针对的是另一种约束：

| | sno-station-skills | agent-foreman |
|---|---|---|
| **成本形态** | 假设两边都是付费订阅 | **一个订阅 + 一个便宜端点** |
| **角色** | 可互换，任一方都能当领导 | **固定且不对称**：Codex 恒为领导 |
| **额度策略** | 额度耗尽后自动交接 | **显式预算 + 人闸** |
| **体量** | 31 个 skill + CLI 安装器 + 配套 App | **4 个 skill，零依赖** |
| **最难那 10% 谁写** | 未规定 | **规定由领导亲自写** |

如果你的处境是「**我只有一个能放心依赖的订阅，另有一个便宜 API**」—— 那就是它填的缺口。

### 已知的局限

- 「Claude Code 的壳接非 Anthropic 模型效果不错」这个说法，目前**只是我们自己的经验，不是 benchmark**。把测量结果发出来在我们的路线图上。
- 领导角色假定你有 Codex 订阅。用 API key 也能跑，但 `docs/architecture.md` 里的额度纪律假定的是**天花板**，不是账单。

---

## 环境要求

| 依赖 | 版本 | 为什么需要 |
|---|---|---|
| **Claude Code** | ≥ 2.1 | 需要 `SKILL.md` 支持和 hook |
| **Codex CLI** | 当前版本（`@openai/codex`） | 担任领导 |
| **Node.js** | ≥ 18.18 | Codex ↔ Claude Code 桥的要求 |
| **git** | 任意 | 契约目录要提交 —— 它就是审计线索 |
| **工人端点** | 任意 Anthropic 兼容 | DeepSeek、中转站、Anthropic 本身…… |

**账号** —— 二者其一即可：

- **ChatGPT 订阅**（官方桥在免费档也能用，付费档额度大得多），或
- **OpenAI API key**。

**可选但推荐：** [`openai/codex-plugin-cc`](https://github.com/openai/codex-plugin-cc) —— 官方桥，让 Claude Code 能直接调起 Codex。

> agent-foreman **不依赖**它：纯文件契约不需要任何桥就能跑通。它只是省掉一次复制粘贴。

---

## 安装

```bash
git clone https://github.com/NJYk1ng/agent-foreman
cd agent-foreman
./install.sh
```

它会按各 skill 的归属分发 —— `agent-contract` 两端都装，`execute-plan` 只装 Claude Code 侧，
`tech-lead` / `cross-review` 只装 Codex 侧。

```bash
./install.sh --dry-run     # 先说清要做什么，不动文件
./install.sh --force       # 覆盖已存在的
./install.sh --uninstall   # 卸掉本仓库装的那些
```

**再往某个项目里放三份协作文件**（推荐）：

```bash
./install.sh --project ~/code/我的项目
```

它会放进项目：

| 文件 | 给谁 | 干什么 |
|---|---|---|
| `AGENTS.md` | Codex | **开场自动读** —— 告诉它"你是领导"、以及「被自动叫醒时先问人再动手」 |
| `CLAUDE.md` | Claude Code | 一行 `@AGENTS.md` 转发（**单一事实来源，两份写一样的迟早走岔**） |
| `.foreman/notify-lead.sh` | 工人 | 干完活跑它，把领导叫醒 |

> ⚠️ **绝不覆盖/删除不是它放的文件。** 项目里本来就有 `AGENTS.md` / `CLAUDE.md` 是常事 ——
> 内容对不上它就拒绝，告诉你该手工加哪一行；卸载时也只删与本仓库逐字节相同的那些。

> ⚠️ **两个 harness 的 skill 格式是同一套，但不自动同步。**
> 实测：只放在 `~/.claude/skills/` 的 skill，Codex 看不到；反之亦然。所以每个 skill 要装到它该去的侧。

**备选：用 [cc-switch](https://github.com/farion1231/cc-switch) 装。** 它的 skill 表里有
`enabled_claude` / `enabled_codex` 两列，正好做同样的事，还带内容 hash 和更新通道。
如果你已经在用 cc-switch，把本仓库加成 skill 源、勾上对应的侧即可，不用跑 `install.sh`。

把工人那个壳指向便宜的端点 —— 在 `~/.claude/settings.json` 里：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://你的端点",
    "ANTHROPIC_AUTH_TOKEN": "<你的 key>",
    "ANTHROPIC_MODEL": "<你的模型>"
  }
}
```

> ⚠️ 别把那个文件提交上去。token 在里面是明文的。

---

## 快速开始

在你的项目仓库里，**开两个终端**（`codex` 一个、`claude` 一个），都在项目根目录。

**1 · 领导出计划.** 在 Codex 里：

```
$tech-lead  <用你自己的话描述要做什么>
```

它写出 `.foreman/PLAN.md` —— 一份任务清单，其中**每条任务的验收标准都是可证伪的**（一条命令 / 一个可观察的事实 / 一条写清了判据的现场步骤）；难的任务会被标注为「由领导亲自写」。

> ⚠️ **提交要等这一步之后** —— `.foreman/` 里得先有文件：
> ```bash
> git add .foreman && git commit -m "chore: 初始化 agent-foreman 契约"
> ```
> （git 不跟踪空目录，所以不能先 `mkdir` 再 `git add`。）

**2 · 工人施工.** 在 Claude Code 里：

```
/execute-plan
```

它读 `PLAN.md`，动手实现，**把每一条验收标准都真跑一遍并把真实输出贴进** `.foreman/STATUS.md`，然后**在计划边界处停下**。

**3 · ⭐ 工人自动叫醒领导 —— 你不用复制粘贴提示词.**

工人写完 `STATUS.md` 会自己跑 `notify-lead.sh`，**把"该你了"推进 Codex 那个会话**，
Codex 就醒了 —— 不需要你走过去、打一段提示词。

它醒来的**第一件事不是干活，是问你**：

```
工人交了 .foreman/STATUS.md：T1 标为 UNVERIFIED，AC1 已通过，AC2–AC4 待你现场验收。
要我现在审查吗？
```

你说「审」它才动手。**这就是那道「花领导额度的动作必须经过人」的闸** ——
只是从"人来启动"变成了"**它自己来问你**"。闸没松，你的手松了。

> 📌 原理：Codex 没有「文件变了就开一轮」的能力（它的 inotify 只盯配置类文件，
> 钩子事件里也没有文件变更类）。但它有 `codex queue` ——
> **能从外面把消息塞进一个正在运行的会话。** `notify-lead.sh` 就是包装了它。
> 实测：TUI 停在提示符上时塞消息，它会自己开一轮。
> 详见 [`scripts/notify-lead.sh`](scripts/notify-lead.sh) 的注释。

**4 · 领导审.** 你说「审」之后，它自己拿 diff 逐条对照验收标准，把发现按 P0–P3 分级写进 `.foreman/REVIEW.md`。**没有任何东西因为是 agent 说的就算完成。**

**5 · 如果工人卡住了**，它写 `.foreman/BLOCKED.md` —— 试过什么，需要你定什么。**要不要为这件事花领导的额度，由你决定。** 这道人闸是特意留的，理由见[额度纪律](docs/architecture.md#额度纪律)。

---

## 设计

四个 skill，一份契约：

| Skill | 装在 | 职责 |
|---|---|---|
| `agent-contract` | **两端都装** | 定义下面的文件契约 —— 唯一一个两边必须逐字节一致的东西 |
| `tech-lead` | Codex | 需求 → `PLAN.md` |
| `cross-review` | Codex | diff → `REVIEW.md` |
| `execute-plan` | Claude Code | `PLAN.md` → 代码 + `STATUS.md` |

`.foreman/` 下的契约文件：

| 文件 | 谁写 | 写什么 |
|---|---|---|
| `PLAN.md` | 领导 | 任务，各带目标、归属、依赖、**验收标准**、边界 |
| `STATUS.md` | 工人 | 逐条验收标准的结果，**含真实命令输出**，以及提交号 |
| `BLOCKED.md` | 工人 | 卡在哪、已试过什么、需要哪个具体决定 |
| `REVIEW.md` | 领导 | 按 P0–P3 分级的发现，外加持 `PLAN.md` 的逐条核对结论 |

**外加三份「不当契约、但要装进项目」的东西**（`install.sh --project` 放进去）：

| 文件 | 给谁 | 干什么 |
|---|---|---|
| `AGENTS.md` | Codex | 开场自动读：你是领导 + **被自动叫醒时先问人再动手** |
| `CLAUDE.md` | Claude Code | 一行 `@AGENTS.md` 转发（单一事实来源） |
| `.foreman/notify-lead.sh` | 工人 | 干完活跑它，把领导叫醒 |

完整规范：[`docs/contract.md`](docs/contract.md)
设计取舍与额度模型：[`docs/architecture.md`](docs/architecture.md)

---

## 项目状态

**Pre-alpha.** 契约、四个 skill、「工人干完自动叫醒领导」都已可用。

- [x] 契约设计 —— [`docs/contract.md`](docs/contract.md)
- [x] 四个 skill：`agent-contract`（两端）+ `execute-plan`（工人）+ `tech-lead`、`cross-review`（领导）
- [x] `install.sh` —— 分发 skill；`--project` 把协作文件放进项目
- [x] **工人干完自动叫醒领导** —— `notify-lead.sh`（走 `codex queue`）+ `AGENTS.md`/`CLAUDE.md` 模板
- [ ] **领导审完自动叫醒工人** —— 要靠文件监听（Claude Code 的 `FileChanged` + `asyncRewake`）
- [ ] 对照测量：同一批任务，领导制 vs 单 agent，比成本与缺陷漏出率

### ⚠️ 为什么最后没走钩子

原本的计划是用钩子做自动接力（Claude Code 的 `Stop` / Codex 的 `stop`）。**实测后放弃了**，
把踩到的东西记在这儿，省得别人再走一遍：

1. **Codex 的项目级钩子有两道信任闸** —— 项目信任 + **每个钩子的哈希信任**。
   没审过的钩子会被**静默跳过，一声不吭**（[#48715](https://github.com/openai/codex/issues/48715)）。
   用户级钩子免了这道，但会全局生效。
2. **`codex exec` 根本不跑钩子** —— 只有交互式 TUI 跑。
3. **Claude Code 的 `FileChanged` 能靠文件变更开一轮，但有个已知 bug**：
   跑过一次 `cd` 之后监听会被**悄悄解除**（[#95440](https://github.com/anthropics/claude-code/issues/95440)）。
   而 agent 干活的每一步都在 `cd`。
4. 绕开来做「钩子里 `sleep` 等对方」也行，代价是**那个终端看起来像卡死**，
   出问题时极难判断是"在等"还是"死了"。

⇒ 改成：**工人干完时跑一条命令，把消息推进领导的会话**（`codex queue`，
实测能叫醒停在提示符上的 TUI）。没有常驻进程、没有钩子、没有额外的信任动作。
**闸还在 —— 只是从"人来启动"变成了"它来问你"。**

## 参与贡献

欢迎 issue 和 PR —— 见 [CONTRIBUTING.md](CONTRIBUTING.md)。**目前最有用的是「失败案例」**：一个因为这种分工反而变得更糟的任务。

## 许可证

Apache-2.0 —— 见 [LICENSE](LICENSE)。
