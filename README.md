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

Pre-alpha 阶段，目录结构还在动。`install.sh` 落地之前，先手动装。

```bash
git clone https://github.com/<you>/agent-foreman
cd agent-foreman

# 共用 skill —— 两个壳都要读，所以两边必须各有一份内容完全相同的副本
cp -r skills/agent-contract ~/.claude/skills/
cp -r skills/agent-contract ~/.codex/skills/

# 领导的 skill
cp -r skills/tech-lead     ~/.codex/skills/
cp -r skills/cross-review  ~/.codex/skills/

# 工人的 skill
cp -r skills/execute-plan  ~/.claude/skills/
```

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

在你的项目仓库里：

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

**3 · 领导审.** 回到 Codex：

```
$cross-review  .foreman/STATUS.md
```

它拿 diff 逐条对照验收标准，把发现按 P0–P3 分级写进 `.foreman/REVIEW.md`。**没有任何东西因为是 agent 说的就算完成。**

**4 · 如果工人卡住了**，它写 `.foreman/BLOCKED.md` —— 试过什么，需要你定什么。**要不要为这件事花领导的额度，由你决定。** 这道人闸是特意留的，理由见[额度纪律](docs/architecture.md#额度纪律)。

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

完整规范：[`docs/contract.md`](docs/contract.md)
设计取舍与额度模型：[`docs/architecture.md`](docs/architecture.md)

---

## 项目状态

**Pre-alpha.** 期一（契约 + 四个 skill）正在写。期二加钩子，让收到的消息在回合边界自动浮出来 —— 但**任何要花领导额度的动作前面留一道人闸**。

- [x] 契约设计 —— [`docs/contract.md`](docs/contract.md)
- [x] `agent-contract`（两端共用）+ `execute-plan`（工人侧）
- [ ] `tech-lead`、`cross-review`（领导侧两个）
- [ ] `install.sh`
- [ ] 钩子（Claude Code `UserPromptSubmit` / `Stop`；Codex `userPromptSubmit` / `stop`）
- [ ] 对照测量：同一批任务，领导制 vs 单 agent，比成本与缺陷漏出率

## 参与贡献

欢迎 issue 和 PR —— 见 [CONTRIBUTING.md](CONTRIBUTING.md)。**目前最有用的是「失败案例」**：一个因为这种分工反而变得更糟的任务。

## 许可证

Apache-2.0 —— 见 [LICENSE](LICENSE)。
