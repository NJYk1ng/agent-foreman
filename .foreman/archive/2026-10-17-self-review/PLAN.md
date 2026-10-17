# PLAN — 补齐 README 承诺的文件，修掉审核发现的 3 条

> 领导：Codex (gpt-6-luna) · 2026-10-16 · 来源：`codex review --commit HEAD` 的发现

## 背景与约束

README 在 `2dfe92a` 已提交，但它引用的文件（`skills/`、`docs/architecture.md`、
`CONTRIBUTING.md`）当时都还不存在；「快速开始」第一步 `mkdir -p .foreman && git add .foreman`
按字面执行会失败（空目录 git 不跟踪）。

这个计划一次解决这 3 条，让 README 里承诺的东西都真实存在。

**不许改**：README 的定位表述、与 sno-station 的差异表 —— 那是和人讨论定稿的。

### T1 让「快速开始」第一步真能跑

- **目标**：照 README 字面执行 `mkdir -p .foreman && git add .foreman` 不再失败
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `git -C . ls-files .foreman | wc -l` → 输出 ≥ 1（目录里有被跟踪的文件）
  - AC2 [观察] 在干净工作区按 README 快速开始的字面步骤走一遍，`git add` 退出码为 0
- **边界**：不许改 README 的章节顺序，不许动已定稿的表述

### T2 把 README 链接的 `docs/architecture.md` 写出来

- **目标**：README 两处指向它的链接不再是死链，且内容覆盖"为什么这么设计"
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `test -f docs/architecture.md` → 退出码 0
  - AC2 [命令] `grep -c '额度纪律' docs/architecture.md` → ≥ 1（README 里那个锚点 `#额度纪律` 要能落到）
  - AC3 [观察] 人工通读一遍，确认它解释了：为什么用文件而不是实时通信、为什么领导只写最难 10%、为什么人闸是设计不是妥协
- **边界**：不许把它写成 README 的复制品

### T3 把 `CONTRIBUTING.md` 写出来

- **目标**：README 里指向它的链接不再是死链
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `test -f CONTRIBUTING.md` → 退出码 0
  - AC2 [命令] `grep -q 'skills/' CONTRIBUTING.md` → 退出码 0（要说明怎么加/改 skill）
  - AC3 [命令] `grep -qiE '失败案例|failure' CONTRIBUTING.md` → 退出码 0（README 说最欢迎的是失败案例，这里要接上）
- **边界**：不许写成一堆流程套话

### T4 把 4 个 skill 的状态在 README 里更新准确

- **目标**：README 的「项目状态」清单与实际相符
- **谁写**：工人
- **依赖**：无
- **验收标准**：
  - AC1 [命令] `grep -c '^\- \[x\]' README.md` → ≥ 1（4 个 skill 里已完成的那两个要打勾）
  - AC2 [观察] 对照 `skills/` 目录实际内容，README 清单没有多写也没有少写
- **边界**：不许提前勾上还没做的（`install.sh`、钩子、对照测量）

## 备注

T4 依赖 T1/T2/T3 的结果（因为清单里要反映它们的状态），实际上应在最后做。
但按契约「新加任务只能追加、不许重排编号」，T4 就是 T4。
