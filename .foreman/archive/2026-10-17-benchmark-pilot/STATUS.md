# STATUS — Benchmark pilot dry run

> 工人：Claude Code (deepseek-flash[1m]) · 2026-10-17 · 提交：`71969db`（AC1 确认后更新本文件）

## T13 单任务双方法 benchmark dry run — 状态：DONE

- **AC1 [现场]**: ✅ 需求方于 2026-10-17 在本对话明确回复「AC1 通过」。
  - 确认内容：任务 `sum-cli`；范围仅 2 runs；token 上限 500,000；金额上限 0 额外按量支出（CNY）；耗时上限 60 分钟。
  - 金额说明：需求方在知悉 Claude CLI 报告的 notional `$1.214867`（两个会话，`costBasis=unknown`）后确认 AC1；该数字不是可验证的账单金额。

- **AC2 [命令]**: ✅
  ```
  $ python3 benchmarks/check_fixtures.py
  ✅ sum-cli: structure + snapshot
  ✅ sum-cli: starting snapshot fails as expected
  ✅ sum-cli: solution passes
  ✅ tag-normalize: structure + snapshot
  ✅ tag-normalize: starting snapshot fails as expected
  ✅ tag-normalize: solution passes
  ✅ wordcount: structure + snapshot
  ✅ wordcount: starting snapshot fails as expected
  ✅ wordcount: solution passes
  fixtures: 3 tasks OK
  rc=0
  ```
  两次 run 的初始快照哈希都与 metadata 一致：
  ```
  A initial_hash ea8821359c7aeb4a5240082d1ecd301fb3beeb67348bcaad45f5e07c686635b9
    expected     ea8821359c7aeb4a5240082d1ecd301fb3beeb67348bcaad45f5e07c686635b9
  B initial_hash ea8821359c7aeb4a5240082d1ecd301fb3beeb67348bcaad45f5e07c686635b9
    expected     ea8821359c7aeb4a5240082d1ecd301fb3beeb67348bcaad45f5e07c686635b9
  ```

- **AC3 [观察]**: ✅
  ```
  $ find benchmarks/runs -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
  20261017T071751Z-A-sum-cli
  20261017T071912Z-B-sum-cli
  ```
  两份 `meta.json` 都含：`method`、`task_id`、`run_order`、`workspace_path`、初始/最终 SHA-256、UTC 起止、`wall_clock_seconds`、`sessions`（session/thread ID + usage 原始字段）、`final_diff_file`、`grader`（命令 + 退出码 + 输出文件）、`human_interventions`。两份都是 `sum-cli`，初始 SHA 相同；session 和 workspace 路径不同。原始记录文件：
  ```
  [A] claude.err claude.jsonl commands.log final.diff grader.out meta.json prompt.txt usage.json
  [B] claude-worker.err claude-worker.jsonl codex-plan.err codex-plan.jsonl codex-review.err codex-review.jsonl commands.log final.diff grader.out meta.json PLAN.md prompt-*.txt REVIEW.md sessions.json STATUS.md
  ```
  两个评分器都在 agent workspace 之外运行，原始输出为空且 `exit_code=0`：
  ```
  20261017T071751Z-A-sum-cli: rc=0 bytes=0
  20261017T071912Z-B-sum-cli: rc=0 bytes=0
  ```

- **AC4 [观察]**: ✅
  ```
  $ for d in benchmarks/runs/*/; do echo "[$(basename "$d")]"; \
      find "$d/workspace-final" -type f -printf '%P\n' | sort; done
  [20261017T071751Z-A-sum-cli]
  sum.sh
  [20261017T071912Z-B-sum-cli]
  sum.sh
  ```
  初始与最终文件清单都只有 `sum.sh`，等于 `metadata.visible_files`。B 的工人工具调用只碰了以下文件：
  ```
  $ grep -o '"file_path":"[^"]*"' .../claude-worker.jsonl | sort -u
  "file_path":"/home/jgyy/.claude/skills/agent-contract/SKILL.md"
  "file_path":"/tmp/foreman-pilot/runs/20261017T071912Z-B-sum-cli/.foreman/PLAN.md"
  "file_path":"/tmp/foreman-pilot/runs/20261017T071912Z-B-sum-cli/.foreman/STATUS.md"
  "file_path":"/tmp/foreman-pilot/runs/20261017T071912Z-B-sum-cli/workspace/sum.sh"
  ```
  工人和两个 Codex 会话的命令里都没有 `benchmarks/tasks`、`test_sum` 或 `/solution/`：
  ```
  $ grep -o '"command":"[^"]*"' .../claude-worker.jsonl | grep -E 'benchmarks/tasks|test_sum|/solution/' || echo none
  none
  $ for f in codex-plan.jsonl codex-review.jsonl; do ...; done
  [codex-plan.jsonl]
  none
  [codex-review.jsonl]
  none
  ```

- **AC5 [观察]**: ✅
  ```
  == A ==
  method A order 1 wall 18 s
  token_total 29540
  claude 2a72cd72-c28c-4f39-a094-68189584e99d
    in 26883 out 2657 cache_read 183424 norm 29540 cost 0.292552

  == B ==
  method B order 2 wall 176 s
  token_total 298980
  codex plan 01a148ba-a0ab-79a3-9570-a33fadce1230
    in 122293 out 2126 cached_input 105344 norm 124419
  claude worker 3727dcf5-4731-4fc0-a7f4-26e497936ab2
    in 36300 out 9511 cache_read 1006080 norm 45811 cost 0.922315
  codex review 01a148bc-6c72-71f0-8e17-7d952bd4c5cc
    in 126353 out 2397 cached_input 102400 norm 128750
  review PASS

  combined: token_total 328520 / cap 500000 (remaining 171480)
            wall_total 194 s / cap 3600 s (remaining 3406)
  ```
  方法 A 是一个全新 `claude -p` 会话从 `task.md` 到最终答复；运行目录不是 git 仓库，task.md 也没有要求 git commit，所以「提交」按最终工作区 + 最终答复记录。方法 B 是全新 `codex exec` 写 PLAN → 全新 `claude -p` 工人实现 / 写 STATUS → 全新 `codex exec` 审 REVIEW（PASS）；PLAN/STATUS/REVIEW 均已复制到 B 的证据目录。cache 字段只作为 input 细分记录，未叠加进 normalized total；Codex 没有 cost 字段，记 `unavailable`。

- **AC6 [命令]**: ✅
  ```
  $ git diff --check
  rc=0
  $ grep -n '对照测量' README.md README.en.md
  README.md:350:- [ ] 对照测量：同一批任务，领导制 vs 单 agent，比成本与缺陷漏出率
  ```
  `[ ] 对照测量` 仍未勾选；本文件只写实际观测，不写「哪种方法更好」的结论。

- **改动**：新增 `.foreman/PLAN.md`（领导写）、`.foreman/STATUS.md`（本文件）；`benchmarks/runs/` 下两个 run 的原始证据（`.gitignore` 已忽略）。没有改代码、README 或夹具。

- **备注**：
  - 这是 dry run：1 个任务 × 2 种方法各 1 次，没有顺序平衡，不能据此判断方法优劣。
  - 为避开夹具认知污染，两个方法都使用全新 CLI 会话，不使用当前 live 会话。
  - Claude 会话使用 `--strict-mcp-config` 和窄 Bash 白名单（只允许 `bash workspace/sum.sh:*`）。B 的工人因此用了 37 turns、15 次 permission denials 才完成等价自证；这是本次 dry run 的工具环境限制，不是方法效果。
  - `docs/benchmark-protocol.md` 顶部仍写「尚未运行 pilot」。本次只是 dry run，没有效能结论；是否更新该状态行由领导决定。
