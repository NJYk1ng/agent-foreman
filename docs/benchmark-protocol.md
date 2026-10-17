# 对照测量协议

> 状态：协议与夹具已建立，**尚未运行 pilot**。
> 本协议不产生“哪种方法更好”的结论；任何 pilot 必须由人另行批准预算并另立计划。

## 一、目的

比较两种方法在同一任务集上的：

- token 成本
- wall-clock
- 隐藏测试缺陷漏出率
- 人工介入次数

**方法 A · 单 agent**：一个会话从任务说明做到提交。

**方法 B · agent-foreman**：Codex 领导写 `PLAN.md`、审 `REVIEW.md`；
Claude Code 工人实现、自证、写 `STATUS.md`。

**本协议只定义怎么测，不预设结论。**

## 二、任务集与固定起点

每个任务在 `benchmarks/tasks/<id>/`：

| 路径 | 作用 |
|---|---|
| `task.md` | 参与者可见的任务说明 |
| `workspace/` | 固定起始快照；`metadata.json` 记录 SHA-256 |
| `grader/` | 评分器 + 隐藏测试；**不进入 agent 可见工作区** |
| `solution/` | 用于校验夹具可解；不提供给 agent |

当前任务：`wordcount`、`sum-cli`、`tag-normalize`。

`workspace/` 的文件清单由 `metadata.visible_files` 固定；校验器拒绝任何多余文件，
防止隐藏测试/评分器副本被误放进 agent 可见目录。

两种方法使用**完全相同**的任务集、起始快照、任务说明和约束。
每次运行把 `workspace/` 复制到新的运行目录；不同运行之间不共享文件、缓存或会话。

## 三、运行控制

- **提示约束**：只给 `task.md`；明确禁止读取 `grader/`、`solution/` 或搜索隐藏测试；
  除非任务说明另有要求，禁止联网和安装依赖。
- **独立会话/工作区**：每个 run 使用新的会话和新的工作区副本；不复用上一轮产物。
- **顺序平衡**：至少两轮。第一轮 A→B，第二轮 B→A；或记录随机种子并随机化。
  任务顺序和运行顺序写入证据。
- **评分**：运行结束后在 agent 工作区之外运行 `grader`；评分器只读工作区。
- **原始证据**：保存会话 ID/日志、usage、起止时间、最终 diff、grader 输出、
  人工介入记录。原始日志放 `benchmarks/runs/<run-id>/`（默认不提交）；
  仓库只提交脱敏摘要。

## 四、指标

### 4.1 token 成本

- 只从会话日志 / provider usage 读取；**不估算**。
- 先记录原始字段：`input_tokens`、`output_tokens`、`cache_read`、`cache_write`，
  以及 provider 提供的 canonical total（如果有）。
- 归一化：
  - cache 字段通常是 input 的**细分**：OpenAI 的 `cached_tokens` 包含在
    `input_tokens` 内；Anthropic 的 `cache_read_input_tokens` /
    `cache_creation_input_tokens` 也属于 input 侧。**不要**把 cache 再加到 input 上。
  - 有 canonical total → 用它；否则 total = `input_tokens + output_tokens`。
  - 不同 provider 字段含义不同；跨 provider 比较前必须用同一归一化定义，
    并在报告里同时给出原始字段和归一化 total。
- 缺失时记 `unavailable`；不填 0、不推算。

### 4.2 wall-clock

- 起点：任务说明交付给 agent 的时间。
- 终点：agent 最终答复 / 会话结束的时间。
- 记录 UTC 时间戳和秒数；人工等待时间单独记录，不混入。

### 4.3 隐藏测试缺陷漏出率

- 分子：该次运行失败的隐藏测试数。
- 分母：该任务隐藏测试总数。
- 任务级 = 分子 / 分母；总体 = 所有失败隐藏测试 / 所有隐藏测试。
- 基础设施错误（评分器崩溃、环境缺失）单独记录，**不计入**分子/分母。
- 隐藏测试和评分器始终在 agent 工作区之外。

### 4.4 人工介入次数

- 计数：人发出的、改变方向/计划/验收的动作（批准计划、打回、改范围、现场验证等）。
- 不计：初始任务说明、最终结果确认、纯等待。
- 每次介入记录时间、原因、影响了哪一步。

## 五、额度与报告规则

- **本协议不授权任何 pilot**；pilot 需要人明确预算并另立计划。
- token 只能来自日志/usage；缺失就写 `unavailable`。
- 报告必须覆盖所有任务和两种方法，包括失败；不许只挑赢的。
- 没有测量就不写“更便宜 / 更可靠 / 更好”的结论。
- 原始证据可能含敏感信息；提交前脱敏，原始日志不进仓库。

## 六、夹具校验

```bash
python3 benchmarks/check_fixtures.py
```

校验器会检查：

- 至少 3 个任务，字段/路径完整，任务 ID 唯一；
- 固定快照的 SHA-256 匹配；
- `workspace/` 的文件集合与 `metadata.visible_files` 完全一致（拒绝多余文件）；
- `grader/`、隐藏测试、`solution/`、`task.md` 不在 agent 可见工作区内；
- 起始快照会被评分器判失败（任务不是已经做完的）；
- 覆盖 `solution/` 后评分器通过（夹具可解）。
