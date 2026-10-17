# STATUS — 消除 agent-foreman 的协作矛盾并补齐安全与自动检查

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：4f47aa1（T1）、6d352dc（T2）、de23aad（T2 复审修复）；本 STATUS 随后单独提交

## T1 统一角色边界、通知流程和执行路径 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rg -n '不要自动去调领导|不要自己去叫领导' skills/execute-plan/SKILL.md templates/global-claude.md templates/AGENTS.md
  （无输出；rg 退出码 1 = 没有匹配）
  ```

  通知行为一致性（同一组文件的命中行）：
  ```
  $ rg -n 'notify-lead|cross-review|codex review' skills/execute-plan/SKILL.md templates/global-claude.md templates/AGENTS.md
  skills/execute-plan/SKILL.md:112:notify-lead
  skills/execute-plan/SKILL.md:122:- ✅ 做完 → 写好 `STATUS.md` → 跑 `notify-lead` → 停下
  skills/execute-plan/SKILL.md:123:- ❌ 做完 → 自己跑 `cross-review` / `codex review` → 花掉的额度没有人同意过
  skills/execute-plan/SKILL.md:127:**`notify-lead` 是叫醒；`cross-review` 才是花钱的审核。**
  skills/execute-plan/SKILL.md:140:- [ ] 跑过 `notify-lead`（叫醒，不是审核）；没有自己跑 `cross-review` / `codex review`
  templates/global-claude.md:25:**干完活**：跑 `notify-lead` —— 它只是叫醒，不是审核；领导会先问人要不要审。
  templates/global-claude.md:26:**不要自己跑 `cross-review` / `codex review`** —— 那才是花额度的审核。
  templates/global-claude.md:34:- ❌ 做完 → 自己触发审核（`cross-review` / `codex review`）—— 叫醒用 `notify-lead` 就够了
  templates/AGENTS.md:22:| 工人交了活 | `REVIEW.md` | `cross-review` |
  templates/AGENTS.md:67:notify-lead
  templates/AGENTS.md:74:**不要自己跑 `cross-review` / `codex review`** —— 那才是花钱的审核。
  ```

  结论：三个入口都要求「跑 `notify-lead` 叫醒；不要自己跑 `cross-review` / `codex review`」。

- **AC2 [观察]**: ✅ 旧角色承诺已清除；八个文件逐项核对如下。
  ```
  $ rg -n '谁写：领导|由领导亲自写|领导亲自写|领导不写代码|不写代码' \
      skills/agent-contract/SKILL.md skills/tech-lead/SKILL.md docs/contract.md \
      README.md README.en.md templates/AGENTS.md templates/global-claude.md templates/global-codex.md
  （无输出；rg 退出码 1 = 没有匹配）
  ```

  逐项命中行（新规则）：

  | 文件 | 命中行 |
  |---|---|
  | `skills/agent-contract/SKILL.md` | `48: - **谁写**：工人`；`59: ### ⭐ 困难任务怎么分：拆小、加严 AC、升级`；`61: 所有实现任务都写 谁写：工人。领导不写实现代码。`；`71-73: 拆小 / 加严 AC / 写清升级点` |
  | `skills/tech-lead/SKILL.md` | `50: - **谁写**：工人`；`93: ### 四、⭐ 困难任务：拆小，不要自己写`；`95: 所有实现任务都写 谁写：工人。领导不写实现代码。`；`107-109: 拆小 / 加严 AC / 写清升级点`；`141: 自查：最难的部分被拆成更小的、可证伪的任务，并写清升级点` |
  | `docs/contract.md` | `48: - **谁写**：工人`；`65: 固定为 工人 —— 所有实现任务由工人执行；领导负责规划和审核`；`70: ### ⭐ 困难任务怎么分：拆小、加严 AC、升级`；`72: 所有实现任务都写 谁写：工人。领导不写实现代码。`；`82-84: 拆小 / 加严 AC / 写清升级点`；`347: - **谁写**：工人` |
  | `README.md` | `39: 把最难的那部分拆成工人能自证的小步`；`87: 难任务怎么处理 ... 必须拆成可证伪的小任务；卡住两次升级给人`；`232: 难的任务会被拆成更小的、可证伪的步骤` |
  | `README.en.md` | `51: turn the hardest parts into small, falsifiable steps the crew can prove`；`109: How hard tasks are handled ... split into falsifiable steps; escalate after two attempts` |
  | `templates/AGENTS.md` | `10: Codex 领导 ... 不做实现`；`39: ### ⭐ 难任务：拆小，不要自己写`；`42: ... 卡住两次 → BLOCKED.md → 由人决定是否请你给方向/改计划`；`67: notify-lead`；`74: 不要自己跑 cross-review / codex review` |
  | `templates/global-claude.md` | `3: 你是【工人】`；`7: 当工人，另一个 agent（Codex）当领导`；`25: 跑 notify-lead —— 只是叫醒，不是审核`；`26: 不要自己跑 cross-review / codex review`；`32: 不写 PLAN.md / REVIEW.md`；`34: 做完不要自己触发审核` |
  | `templates/global-codex.md` | `15: 不做实现`；`16-17: 困难任务也不要自己写 ... 拆小 / 加严 AC / 卡住两次升级` |

  结论：领导负责规划/审核，所有实现任务 `谁写：工人`；困难任务按「拆小 / 加严 AC / 卡住两次升级」处理。

- **AC3 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **改动**：
  - `2f734f5`：归档旧计划三件套 + 采用 Codex 新 PLAN
  - `4f47aa1`：T1 实现（12 个文件）
- **边界核对**：未改变额度闸门；未引入 `LEAD_STATUS.md` 或新的代码交接机制。
- **部署备注**：仓库内的 skill/模板已更新；已安装到 `~/.claude/skills` / `~/.codex/skills` 的是副本，
  需 `./install.sh --force` 才会生效。本轮没有动用户真实 HOME 的安装副本。
- **未纳入 T1 的已知后续**：`docs/contract.md` 的旧 `⏸` 措辞 / 「钩子（期二）」 / 7.3k、
  README 死锚点、STATUS 提交时序等，按 PLAN 由 T5 处理。

---

## T2 修复安装器卸载、覆盖备份和冲突提示 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ bash tests/test-install.sh
  [1] 缺结束标记
    ✅ 退出码为 3
    ✅ 目标文件逐字节不变
    ✅ 错误信息说明结束标记缺失
  [2] 标记错序
    ✅ 错序标记退出码为 3
    ✅ 错序标记文件逐字节不变
    ✅ 错误信息说明标记不成对
  ```
  两个用例都构造损坏的全局文件（缺结束标记 / 结束标记在开始之前），再 `--uninstall`；
  preflight 在任何删除之前退出 3，目标文件与操作前逐字节一致（`cmp -s` 通过）。

- **AC2 [命令]**: ✅
  ```
  [3] 默认安装 / --force 备份
    ✅ 默认安装退出码为 0
    ✅ 默认安装保留用户版本
    ✅ --force 安装退出码为 0
    ✅ --force 装入仓库版本
    ✅ 备份内容与用户原版本一致
  ```

- **AC3 [命令]**: ✅
  ```
  [4] 项目文件冲突
    ✅ 项目安装退出码为 0
    ✅ AGENTS.md 冲突提示可用且不自引用
    ✅ 默认不覆盖用户 AGENTS.md
    ✅ 项目 --force 退出码为 0
    ✅ 项目 --force 覆盖前备份了原文件
  ```

- **AC4 [命令]**: ✅
  ```
  [8] 语法检查
    ✅ bash -n install.sh
  ```

- **汇总**：`PASS=26 FAIL=0`（`bash tests/test-install.sh` 退出码 0）
- **改动**：`install.sh`（T2 首轮 + 复审修复）、新增 `tests/test-install.sh`（26 个断言）
- **提交**：`6d352dc`（首轮）、`de23aad`（复审修复）
- **边界核对**：
  - 默认安装仍保留内容不同的同名 skill 和项目文件（AC2 / AC3 用例）。
  - 卸载保留标记段之外的 `SENTINEL-TOP` / `SENTINEL-AFTER`，并保留符号链接和用户改过的
    `notify-lead`（额外用例 5 / 6 / 7）。
  - 未改变额度闸门，未引入新的交接机制。
- **备注**：首轮审查 BLOCK（P1 标记错序，见 `d08028b`），已修复并补充回归，等待复审。
  T1 审查 PASS（`27a1d4d`），本任务在其后执行。

### 复审修复（P1）— 状态：DONE

- **发现**：孤立的结束标记在前、开始标记在后时，旧 preflight 只确认两者都存在，
  卸载会把未闭合开始标记之后的内容当成我们那段删掉。
- **修复**：preflight / `put_global` / 两个 Python 写入统一要求“开始、结束各恰好 1 个，
  且结束在开始之后”；卸载按起止索引切片，不再逐行 `skip`。
- **复现**（Codex 给的原场景）：
  ```
  $ HOME=... ./install.sh --uninstall
  install.sh: Claude Code 全局记忆 里的 agent-foreman 标记不成对：.../CLAUDE.md
              开始标记 1 个，结束标记 1 个；要求各恰好 1 个，且结束在开始之后。
              拒绝安装/卸载/修改，文件保持原样。
  exit=3
  FILE_UNCHANGED
  ```
- **回归**：新增 `[2] 标记错序`；完整套件 `PASS=26 FAIL=0`。
- **提交**：`de23aad`
