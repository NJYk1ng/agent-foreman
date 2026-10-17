# STATUS — Benchmark pilot 完成后的文档与生成物清理

> 工人：Claude Code (deepseek-flash[1m]) · 2026-10-17 · 提交：`c16ae5e`

## T14 清理 benchmark pilot 状态与生成物 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rm -rf benchmarks/__pycache__ && test ! -e benchmarks/__pycache__
  AC1_rc=0
  $ find . -name '__pycache__' -type d -not -path './.git/*' -print
  # 无输出
  ```

- **AC2 [观察]**: ✅
  ```
  $ sed -n '1,10p' docs/benchmark-protocol.md
  # 对照测量协议

  > 状态：协议与夹具已建立；2026-10-17 完成 **1 task × 2 methods 的 dry run**（2 runs），
  > 记录见 [归档 PLAN](../.foreman/archive/2026-10-17-benchmark-pilot/PLAN.md) 与
  > [归档 STATUS](../.foreman/archive/2026-10-17-benchmark-pilot/STATUS.md)。
  > 本次 dry run **没有方法效果结论**；README 的 `[ ] 对照测量` 仍未勾选。
  > 任何正式 pilot 必须由人另行批准预算并另立计划。
  ```
  两个归档链接都指向现存文件；同段明确写了没有效果结论、README 复选框未勾选。

- **AC3 [命令]**: ✅
  ```
  $ rg -n 'benchmark-pilot|2026-10-17|dry run|已完成' docs/benchmark-pilot-handoff.md
  1:# Benchmark Pilot Handoff（已完成）
  3:> 2026-10-17：benchmark pilot 的 **1 task × 2 methods dry run** 已完成。
  9:- 计划与工人汇报：`.foreman/archive/2026-10-17-benchmark-pilot/`
  16:## 这次 dry run 是什么
  positive_rc=0

  $ ! rg -n '尚未运行 pilot|先让 Codex|T12 只建了协议|预算等我确认' docs/benchmark-pilot-handoff.md
  negative_rc=0
  ```
  handoff 已改成简短的完成说明，指向归档；不再包含过时的未运行 / 待启动指引。

- **AC4 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && \
      bash tests/test-install.sh && bash tests/test-notify-lead.sh && \
      python3 scripts/check-links.py && python3 benchmarks/check_fixtures.py
  ...
  foreman-check: 通过
  PASS=7 FAIL=0
  PASS=33 FAIL=0
  PASS=24 FAIL=0
  链接检查通过：26 个本地链接/锚点
  fixtures: 3 tasks OK
  AC4_rc=0
  ```

- **AC5 [命令]**: ✅
  ```
  $ git diff --check
  diff_check_rc=0
  $ git diff --exit-code -- README.md README.en.md
  readme_diff_rc=0
  $ grep -n '对照测量' README.md README.en.md
  README.md:350:- [ ] 对照测量：同一批任务，领导制 vs 单 agent，比成本与缺陷漏出率
  ```
  README.md / README.en.md 无改动；`[ ] 对照测量` 仍未勾选。

- **改动**：`docs/benchmark-protocol.md`（状态行）、`docs/benchmark-pilot-handoff.md`（改为完成说明）；删除 `benchmarks/__pycache__/`（gitignored，不在提交里）。没有改代码、测试、夹具、README 或归档内容。
- **备注**：本次只整理文档与生成物，没有新增 pilot 效果结论；`benchmarks/runs/` 的原始证据保留在本机、未提交。
