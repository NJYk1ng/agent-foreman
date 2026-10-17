# STATUS — README 使用指南入口与本地 v1.0.0 标签

> 工人：Claude Code (deepseek-flash[1m]) · 2026-10-17 · 提交：`f0b21a0`（计划）+ `27eb3a2`（README 实现 / tag 目标）

## T16 在 README TL;DR 增加使用指南入口并创建本地 tag — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ python3 - <<'PY'
  ... 两份 README 的 TL;DR 各恰好一行 docs/usage.md 链接 ...
  PY
  README TL;DR usage links: 2 files OK
  AC1_rc=0
  ```

- **AC2 [命令]**: ✅
  ```
  $ python3 scripts/check-links.py
  链接检查通过：28 个本地链接/锚点
  AC2_rc=0
  ```

- **AC3 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && \
      bash tests/test-install.sh && bash tests/test-notify-lead.sh
  foreman-check: 通过
  PASS=7 FAIL=0
  PASS=33 FAIL=0
  PASS=24 FAIL=0
  AC3_rc=0
  ```

- **AC4 [命令]**: ✅
  ```
  $ git diff --check
  diff_check_rc=0
  $ git diff --name-only
  README.en.md
  README.md
  ```
  README 两文件作为一个单独提交 `27eb3a2`，不夹带其他文件。

- **AC5 [命令]**: ✅
  ```
  $ test "$(git cat-file -t v1.0.0)" = tag
  type_rc=0
  $ test "$(git rev-parse 'v1.0.0^{}')" = "$(git rev-parse HEAD)"
  target_rc=0
  $ git merge-base --is-ancestor 896c6d3 "$(git rev-parse 'v1.0.0^{}')"
  ancestor_rc=0
  tag_commit=27eb3a2910b2d0f0da4e7e0f14096ed955c36706
  head=27eb3a2910b2d0f0da4e7e0f14096ed955c36706
  ```
  `v1.0.0` 是 annotated tag，创建时指向 README 提交 `27eb3a2`，且包含 T13–T15 审核提交 `896c6d3` 与 T15 PASS 复验 `6adccab`。本 STATUS 提交在 tag 之后，所以现在 HEAD 已前进；tag 仍固定在 `27eb3a2`，未移动。

- **改动**：`README.md` / `README.en.md` 的 TL;DR 各新增一行 `docs/usage.md` 链接；创建本地 annotated tag `v1.0.0`。没有改代码、skills、templates、tests、fixtures 或 `docs/usage.md`。
- **备注**：tag 只在本地，**未 push、未发 GitHub release**；正式对照测量不在本轮范围。
