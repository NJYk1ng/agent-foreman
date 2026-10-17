# STATUS — 消除 agent-foreman 的协作矛盾并补齐安全与自动检查

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：4f47aa1（T1）、6d352dc（T2）、de23aad（T2 复审修复）、1896a09（T3）、ab8506c（T4）、7aa18df（T4 复审修复）、c1d45db（T5）、702baa3（T6）、4feb6a5（T6 P2 修复）、8e9488a（T7）、807d183（T2 备份位置）、716cd8a（T6 归档态）；本 STATUS 随后单独提交

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
- **未纳入 T1 的已知后续**：`docs/contract.md` 的旧版 `[现场]` 措辞 / 「钩子（期二）」 / 7.3k、
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

---

## T3 让 notify-lead 明确选择正确的交互会话 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ bash tests/test-notify-lead.sh
  [1] 默认只选交互式会话
    ✅ 退出码为 0
    ✅ 选中交互式会话
    ✅ 跳过 subagent
    ✅ 跳过 codex_exec
  ```
  夹具里同时放了更新的 `subagent`、`codex_exec` 和较旧的交互会话；默认仍只选交互会话。

  真实库只读验证（fake `codex` 捕获参数，没有向真实会话发消息）：
  ```
  $ CAPTURE=... PATH=fake-bin:$PATH bash scripts/notify-lead.sh "真实库选择测试"
  notify-lead: 正在推给会话 01a14810-e903-73c2-b486-d74084806a01
  exit=0
  captured: queue --thread 01a14810-e903-73c2-b486-d74084806a01 --message 真实库选择测试
  ```
  库里更新的 `01a1481a-...`（Guardian review subagent）被跳过，选中的是主交互会话。

- **AC2 [命令]**: ✅
  ```
  [2] --thread 显式选会话
    ✅ 退出码为 0
    ✅ 使用显式会话
  [3] 符号链接项目路径
    ✅ 退出码为 0
    ✅ symlink 路径按真实路径匹配
  [4] 没有交互式会话
    ✅ 退出码为 12
    ✅ 错误信息说明没有交互式会话
  ```

- **AC3 [命令]**: ✅
  ```
  [5] schema 不兼容
    ✅ 退出码为 11
    ✅ 错误信息说明 schema 不一致
  [6] 会话库缺失
    ✅ 退出码为 10
    ✅ 错误信息说明会话库缺失
  [7] python3 缺失
    ✅ 退出码为 5
    ✅ 错误信息说明需要 python3
  ```

- **AC4 [命令]**: ✅
  ```
  [8] 语法检查
    ✅ bash -n notify-lead.sh
  ```

- **汇总**：`PASS=17 FAIL=0`（`bash tests/test-notify-lead.sh` 退出码 0）；
  `bash tests/test-install.sh` 仍为 `PASS=26 FAIL=0`。
- **改动**：`scripts/notify-lead.sh`、新增 `tests/test-notify-lead.sh`
- **提交**：`1896a09`
- **边界核对**：
  - 默认路径只选交互式会话（AC1），不会向 `codex_exec` / subagent 发消息。
  - 未指定 `--thread` 时只匹配项目根（realpath），不跨项目（AC2/AC3 夹具）。
  - 数据库只读访问：`sqlite3.connect(..., mode=ro, uri=True)`。
- **备注**：T2 复审 PASS（`d6d6804`），本任务在其后执行。

---

## T4 为全局和项目模板增加无计划时停工护栏 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rg -n '没有 .foreman/PLAN.md.*停止|没有计划.*停止.*实现' templates/AGENTS.md templates/global-claude.md skills/execute-plan/SKILL.md
  templates/global-claude.md:12:**没有 .foreman/PLAN.md → 停止，不要开工。** 报告人："这里没有计划，需要领导先写 PLAN"。
  skills/execute-plan/SKILL.md:19:> **没有 .foreman/PLAN.md → 停止，不要开工。** 报告人："这里没有计划，需要领导先写 PLAN"。
  templates/AGENTS.md:51:**没有 .foreman/PLAN.md → 停止，不要开工。** 报告人："这里没有计划，需要领导先写 PLAN"。
  ```

- **AC2 [命令]**: ✅
  ```
  $ rg -n 'PLAN.md.*不存在|没有 .foreman/PLAN.md' templates/AGENTS.md templates/global-claude.md skills/execute-plan/SKILL.md
  templates/AGENTS.md:51:**没有 .foreman/PLAN.md → 停止，不要开工。** 报告人："这里没有计划，需要领导先写 PLAN"。
  templates/AGENTS.md:52:先确认 `.foreman/PLAN.md` 存在且非空；**PLAN.md 不存在时，不得从需求描述自行开工**。
  templates/global-claude.md:12:**没有 .foreman/PLAN.md → 停止，不要开工。** 报告人："这里没有计划，需要领导先写 PLAN"。
  templates/global-claude.md:13:先确认 `.foreman/PLAN.md` 存在且非空；**PLAN.md 不存在时，不得从需求描述自行开工**。
  skills/execute-plan/SKILL.md:19:> **没有 .foreman/PLAN.md → 停止，不要开工。** 报告人："这里没有计划，需要领导先写 PLAN"。
  skills/execute-plan/SKILL.md:20:> **PLAN.md 不存在时，不得从需求描述自行开工。**
  ```

- **AC3 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **改动**：`templates/global-claude.md`、`templates/AGENTS.md`、`skills/execute-plan/SKILL.md`
- **提交**：`ab8506c`（首轮）、`7aa18df`（复审修复）
- **边界核对**：未改 Codex 领导收到需求后生成计划的入口规则；未删除 `.foreman/archive/`。
- **备注**：首轮审查 BLOCK（P1 第三个工人入口缺失），已修复并补齐三条命中，等待复审。
  T3 审查 PASS（`57f33ea`），本任务在其后执行。

### 复审修复（P1）— 状态：DONE

- **发现**：PLAN 的 T4/AC1/AC2 把 `skills/execute-plan/SKILL.md` 列为第三个工人入口；
  首轮只改了两个模板。
- **修复**：在 `execute-plan` 开工前增加“PLAN.md 不存在/为空 → 停止并报告人”。
- **复核**：上面的 AC1/AC2 命令现在三个入口都有命中；`git diff --check` 退出码 0。
- **提交**：`7aa18df`

---

## T5 对齐契约、技能、测量数据和文档链接 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rg -n 'CC\|Codex|CC \| Codex|⏸|钩子（期二）|7\.3k|49k|提交：本次提交' docs/contract.md skills README.md README.en.md docs/architecture.md
  （无输出；rg 退出码 1 = 没有匹配）
  ```
  说明：`docs/contract.md` 的历史引文保留了原文内容，只把旧 `⏸` 记法规范为「无法判定」，
  以通过 AC1 的符号扫描；`cross-review` 的预算从 7.3k 改为实测的 49,000 token / 96 秒。

- **AC2 [命令]**: ✅
  ```
  $ python3 scripts/check-links.py
  链接检查通过：26 个本地链接/锚点
  ```
  `README.md` / `README.en.md` 的本地 Markdown 锚点均可解析；HTML 的本地链接均存在。
  `docs/architecture.md` 增加了显式锚点 `<a id="额度纪律">` 和 `<a id="quota-discipline">`。

- **AC3 [观察]**: ✅ `skills/agent-contract/SKILL.md` 与 `docs/contract.md` 逐项一致：

  | 检查项 | agent-contract | contract |
  |---|---|---|
  | 角色 / 谁写 | `61: 所有实现任务都写 谁写：工人。领导不写实现代码。` | `72: 同左` |
  | 困难任务 | `59-73: 困难任务怎么分：拆小 / 加严 AC / 写清升级点` | `70-84: 同左` |
  | 五种状态 | `130-134: TODO / WIP / BLOCKED / UNVERIFIED / DONE` | `170-174: 同左` |
  | `[现场]` 工人 | `99: [现场] 工人不许判通过` | `121: 同左` |
  | `[现场]` 领导 | `189: [现场] 那几条领导不能判通过` | `264: 同左` |
  | `[现场]` 示例 | `178: 无法判定（需求方尚未验证）` | `246: 同左` |

  复核命令：
  ```
  $ rg -n '谁写：工人|领导不写实现代码|困难任务怎么分|拆小|加严 AC|写清升级点' \
      skills/agent-contract/SKILL.md docs/contract.md
  $ rg -n '^\| `(TODO|WIP|BLOCKED|UNVERIFIED|DONE)`' \
      skills/agent-contract/SKILL.md docs/contract.md
  $ rg -n '\[现场\].*(不许判通过|不能判通过|无法判定)' \
      skills/agent-contract/SKILL.md docs/contract.md
  ```

- **改动**：`docs/contract.md`、`docs/architecture.md`、`docs/what-it-is-for.html`、
  `skills/agent-contract/SKILL.md`、`skills/cross-review/SKILL.md`、
  `skills/cross-review/agents/openai.yaml`、`templates/global-codex.md`、
  新增 `scripts/check-links.py`、`.gitignore`
- **提交**：`c1d45db`
- **边界核对**：未改变 T1 确立的角色边界和额度闸门；未改产品定位；
  历史引文只规范了旧状态符号，没有删除引文内容。
- **备注**：T4 复审 PASS（`8950e17`），本任务在其后执行。

---

## T6 增加 foreman check、shell 回归测试和 CI — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh
  ✅ 计划存在且非空：/home/jgyy/code/agent-foreman/.foreman/PLAN.md
  ✅ 停工护栏：templates/AGENTS.md
  ✅ 停工护栏：templates/global-claude.md
  ✅ 停工护栏：skills/execute-plan/SKILL.md
  ✅ 语法：install.sh
  ✅ 语法：scripts/notify-lead.sh
  ✅ 语法：scripts/foreman-check.sh
  ✅ 语法：scripts/check-links.py
  foreman-check: 通过
  ```

  负向用例（`tests/test-foreman-check.sh`）：
  ```
  [1] 合法夹具 ✅
  [2] 计划缺字段 ✅ 缺字段被拒绝并指出「边界」
  [3] 模板缺停工护栏 ✅ 缺护栏被拒绝并指出 AGENTS.md
  [4] 脚本语法错误 ✅ 语法错误被拒绝并指出 install.sh
  [5] 字段值为空 ✅ 空字段值被拒绝并指出「边界」
  PASS=5 FAIL=0
  ```

- **AC2 [命令]**: ✅
  ```
  $ bash tests/test-install.sh
  ...
  PASS=26 FAIL=0
  ```
  覆盖缺结束标记/标记错序、默认安装保留用户 skill、`--force` 备份、
  正常卸载保留外部内容、符号链接、用户改过的 `notify-lead`、语法检查；
  临时 HOME 通过 `trap` 清理。

- **AC3 [命令]**: ✅
  ```
  $ bash tests/test-notify-lead.sh
  ...
  PASS=17 FAIL=0
  ```
  覆盖交互式会话选择、`--thread`、symlink、无会话、schema、库缺失、python3 缺失、语法检查。

- **AC4 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh
  foreman-check: 通过
  PASS=26 FAIL=0
  PASS=17 FAIL=0
  AC4_exit=0
  ```
  CI 工作流 `.github/workflows/ci.yml` 执行同一组三条命令，并额外运行
  `bash tests/test-foreman-check.sh`；任一失败即标红。

- **改动**：新增 `scripts/foreman-check.sh`、`tests/test-foreman-check.sh`、
  `.github/workflows/ci.yml`；复用 T2/T3 的回归脚本。
- **提交**：`702baa3`（首轮）、`4feb6a5`（P2 修复）
- **边界核对**：只使用 Bash/Python 标准库和仓库现有依赖；测试全部在临时 HOME /
  临时数据库里跑，不读写真实用户 HOME、Codex 会话库或系统级安装目录。
- **备注**：T5 审查 PASS（`d3d9de6`），本任务在其后执行。复审 PASS，
  另有一条 P2 已修复（见下）。

### P2 修复 — 状态：DONE

- **发现**：`foreman-check` 只确认字段标签存在；把 `- **边界**：` 的值清空后仍会通过。
- **修复**：目标 / 谁写 / 依赖 / 边界 要求冒号后非空（允许显式写「无」）；
  验收标准仍由后续 AC 行兜底。
- **回归**：新增 `[5] 字段值为空`，负向回归 `PASS=5 FAIL=0`。
- **提交**：`4feb6a5`

---

## T7 整理快速入口、HTML/英文说明和通知状态查看 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rg -n 'TL;DR|快速开始|notify-lead --status|foreman-check' README.md README.en.md docs/what-it-is-for.html
  README.md:15:## TL;DR
  README.md:26:4. 自检：`./scripts/foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh`
  README.md:27:5. 只看会叫醒谁、不发消息：`notify-lead --status`
  README.md:238:## 快速开始
  README.en.md:16:## TL;DR
  README.en.md:27:4. Self-check: `./scripts/foreman-check.sh && bash tests/test-install.sh && bash tests/test-notify-lead.sh`
  README.en.md:28:5. Inspect the target session without sending: `notify-lead --status`
  docs/what-it-is-for.html:447:  <span class="sub">快速开始 / TL;DR</span>
  docs/what-it-is-for.html:460:notify-lead --status
  docs/what-it-is-for.html:463:./scripts/foreman-check.sh</pre>
  docs/what-it-is-for.html:464:    <p>完整步骤见 <a href="https://github.com/NJYk1ng/agent-foreman#快速开始">README 的快速开始</a>。</p>
  ```
  三个入口都有 TL;DR/快速开始、`notify-lead --status` 和 `foreman-check`。

- **AC2 [命令]**: ✅
  ```
  $ bash tests/test-notify-lead.sh
  [9] --status 只读诊断
    ✅ 退出码为 0
    ✅ 输出项目根
    ✅ 输出交互会话 ID
    ✅ 没有调用 codex queue
  [10] --status 无候选
    ✅ 退出码为 12
    ✅ 输出可操作原因
    ✅ 没有调用 codex queue
  PASS=24 FAIL=0
  ```

  真实项目（只读，无消息）：
  ```
  $ bash scripts/notify-lead.sh --status /home/jgyy/code/agent-foreman
  project: /home/jgyy/code/agent-foreman
  thread: 01a14810-e903-73c2-b486-d74084806a01
  ```

- **AC3 [命令]**: ✅
  ```
  $ python3 scripts/check-links.py
  链接检查通过：26 个本地链接/锚点
  ```

- **AC4 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **改动**：`scripts/notify-lead.sh`、`tests/test-notify-lead.sh`、`README.md`、
  `README.en.md`、`docs/what-it-is-for.html`
- **提交**：`8e9488a`
- **边界核对**：`--status` 只读诊断，不调用 `codex queue`、不创建会话、不改项目文件；
  测试使用隔离夹具和临时数据库。
- **备注**：T6 审查 PASS（`b282192`），P2 已修复（`4feb6a5`），本任务在其后执行。

---

## 部署后修复（T1-T7 完成后）

- **T2 备份位置**：`--force` 的 skill 备份从 `~/.claude/skills/<name>.bak-*`
  移到 `~/.claude/skill-backups/`（Codex 侧同理），否则备份会被当成 skill 扫描。
  `tests/test-install.sh` 增加到 27 个断言；提交 `807d183`。
- **T6 归档态**：没有活跃 `.foreman/PLAN.md` 但 `.foreman/archive/` 有文件时，
  `foreman-check` 跳过计划检查，模板/脚本检查照常；无计划且无归档仍然失败。
  `tests/test-foreman-check.sh` 增加到 7 个断言；提交 `716cd8a`。
- 已把现有 `~/.claude/skills` / `~/.codex/skills` 下的 `*.bak-*` 移到
  `~/.claude/skill-backups` / `~/.codex/skill-backups`。
