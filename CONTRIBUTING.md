# 参与贡献

## ⭐ 现在最有用的是「失败案例」

这个项目还很年轻，**它最缺的不是功能，是反例**。

所以如果你用过之后觉得"这个分工反而更糟"，那是最有价值的报告。请开一个 issue，说清：

| 要写什么 | 为什么重要 |
|---|---|
| **任务是什么**（能脱敏就脱敏） | 没有它无法判断是不是同一类问题 |
| **你怎么分工的**（谁是领导、谁是工人、什么档位） | 档位会影响审核质量，这是实测过的 |
| **在哪一步变糟的** | 是计划写歪了？工人理解错了？审核没抓到？还是只是更慢了？ |
| **你原本会怎么做** | 用来对照 —— 可能只是这个场景本来就不该用这套 |

**不需要有结论。** "我说不清为什么，但就是更别扭"也是有效报告。

---

## 加一个 skill

skill 目录结构（两个 harness 共用同一套格式）：

```
skills/<skill-name>/
├── SKILL.md              必需
│   ├── YAML frontmatter  必需：name + description
│   └── Markdown 正文     调用时才加载
└── agents/
    └── openai.yaml       可选：Codex 侧的 UI 信息
```

### frontmatter 的三条要求

```yaml
---
name: my-skill
description: <一句话，说明【什么时候用】—— 这是唯一的路由信号>
metadata:
  short-description: <短标签，Codex 界面里显示用>
---
```

1. **`name` / `description` 是唯一在"选 skill"阶段可见的东西** ——
   写得含糊，该用的时候就不会被用上。**正文写多长都不占常驻开销，描述写不准才致命。**
2. **`metadata.short-description` 不是可选的。** 实测：Codex 启动时会报
   `Skills/list missing short_description count`，缺了它界面里显示不全。
3. **正文必须自包含。** skill 会被拷到 `~/.claude/skills/` 和 `~/.codex/skills/`，
   **读不到仓库里的 `docs/`** —— 引用仓库文件就是死链。

### `agents/openai.yaml` 怎么用

```yaml
interface:
  display_name: "Human Readable Name"
  short_description: "短标签"
policy:
  allow_implicit_invocation: false     # ⭐ 只在需要"必须显式触发"时加
```

`allow_implicit_invocation` 默认是 `true`。**审核类、审计类 skill 应该设 `false`** ——
否则它会在不相干的场合自动跑起来，而每次自动跑都可能花掉不该花的额度。

### 改完要自测

至少验证这三件：

```bash
# 1. frontmatter 能被解析
head -6 skills/<name>/SKILL.md

# 2. 装到两侧后真的出现（Claude Code 侧立刻生效）
cp -r skills/<name> ~/.claude/skills/

# 3. 描述能把你引到它 —— 换个说法问一遍，看会不会被选中
```

---

## 改契约

`docs/contract.md` 是**四个 skill 共同的地基**。改它要格外小心：

- 改了格式 ⇒ **四个 skill 都要跟着改**，一次提交里改完。
- 加了新的必填字段 ⇒ 现有的 `.foreman/PLAN.md` 会变成不合规。
- **改验收标准的分级或状态词是破坏性变更** —— 请在 PR 里说清动机，以及你遇到的那个
  让现有设计不够用的场景。

---

## 提交

- **一次提交说清一件事。** commit message 写「改了什么 + 为什么」——
  "为什么"比"什么"重要，因为"什么"git 已经记了。
- **代码里不留旧版本。** 不要"把旧的注释掉、新的写在下面" —— 用 git 记账。
- 中文或英文都行，保持一致即可。

---

## 关于 AI 提交的 PR

这个项目本来就是给 AI agent 用的，所以**不反对 agent 提交的 PR**。只有一条要求：

> **说明是哪一步、由谁（哪个 harness、哪个档位）做的。**

理由：本项目全部的设计取舍都来自实测，**实测的可信度取决于能否复现**。少了这条信息，
你的结果就没法被别人对照。
