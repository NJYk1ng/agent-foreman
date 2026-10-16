# STATUS — 补齐 README 承诺的文件，修掉审核发现的 3 条

> 工人：Claude Code (deepseek-flash) · 2026-10-16 · 提交：本次提交

## T1 让「快速开始」第一步真能跑 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ git ls-files .foreman | wc -l
  1
  ```
- **AC2 [观察]**: ✅ `git add .foreman` 退出码 0（见下）
  ```
  $ git add .foreman; echo "退出码=$?"
  退出码=0
  ```
- **改动**：`README.md:155-170`、`README.en.md` 对应段落
  —— 把「提交契约」从快速开始的第一步**挪到第 1 步之后**，并加了说明。
- **说明**：根因是原写法 `mkdir -p .foreman && git add .foreman` —— 空目录 git 不跟踪，
  `git add` 必然失败。现在改成了"先由领导写出 `PLAN.md`，再提交"。

## T2 把 `docs/architecture.md` 写出来 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ test -f docs/architecture.md; echo "退出码=$?"
  退出码=0
  ```
- **AC2 [命令]**: ✅
  ```
  $ grep -c '额度纪律' docs/architecture.md
  1
  ```
- **AC3 [观察]**: ✅ 三处都在 —— 下面是**可 grep 的引文**，领导直接验，不用重读：
  - 「用文件不用实时通信」→ `grep -n '为什么用文件交接' docs/architecture.md` ⇒ `28:## 二、⭐ 为什么用文件交接，不用实时通信`
    结论句 `grep -n 'cat. 出来的协议' docs/architecture.md` ⇒ `54:> **能 \`cat\` 出来的协议，才是能调试的协议。**`
    三条理由（回合制 / 每条消息在之后每轮重发 / 干扰）是该节的三个小标题，在 30~52 行之间。
  - 「领导只写最难 10%」→ `grep -n '为什么领导只写最难' docs/architecture.md` ⇒ `58:## 三、⭐ 为什么领导只写最难的 10%`
  - 「人闸是设计不是妥协」→ `grep -n '额度纪律' docs/architecture.md` ⇒ `77:## 四、⭐ 额度纪律`
    论据句 `grep -n '停下来问' docs/architecture.md` ⇒ `94:一个"停下来问"的设计，在额度受限的场景里，比一个"全自动"的设计**更可靠**…`
- **改动**：新增 `docs/architecture.md`（约 165 行）

## T3 把 `CONTRIBUTING.md` 写出来 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ test -f CONTRIBUTING.md; echo "退出码=$?"
  退出码=0
  ```
- **AC2 [命令]**: ✅
  ```
  $ grep -q 'skills/' CONTRIBUTING.md; echo "退出码=$?"
  退出码=0
  ```
- **AC3 [命令]**: ✅
  ```
  $ grep -qiE '失败案例|failure' CONTRIBUTING.md; echo "退出码=$?"
  退出码=0
  ```
- **改动**：新增 `CONTRIBUTING.md`（约 100 行）

## T4 README 的「项目状态」清单更新准确 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ grep -c '^- \[x\]' README.md
  2
  ```
- **AC2 [观察]**: ✅ 对照 `skills/` 实际内容逐条核对：
  ```
  README.md 清单：                 skills/ 实际：
    [x] 契约设计                     docs/contract.md        ✅ 存在
    [x] agent-contract + execute-plan skills/agent-contract/  ✅ 存在
                                     skills/execute-plan/    ✅ 存在
    [ ] tech-lead、cross-review                              ✅ 确实还没写
    [ ] install.sh                                           ✅ 确实还没有
    [ ] 钩子                                                 ✅ 确实还没有
    [ ] 对照测量                                             ✅ 确实还没做
  ```
  没有多写，也没有少写。
- **改动**：`README.md:222-227`、`README.en.md` 对应段落

---

## 备注（超出计划的部分）

- **T4 的编号**：计划里我自己注明了 T4 实际应在 T1~T3 之后做。按契约「只能追加、
  不许重排编号」，编号保持不动，顺序在计划备注里说明 —— 执行时也照此办理。
- **没有触发任何花领导额度的动作**：本轮全程只做了工人侧的事，
  没有调用 `tech-lead` / `cross-review`，也没有跑 `codex review`。
- **未做的事**：`.foreman/PLAN.md` 和本文件本身现在会进 git。如果不想让它们进仓库，
  需要在 `.gitignore` 里加规则 —— 但契约默认是**提交**（`.gitignore` 里有 `!.foreman/`），
  所以按契约执行了。

## 可以叫领导审了

全部 4 个任务的 AC 都有结论且通过。可以跑：

```
$cross-review  .foreman/STATUS.md
```
