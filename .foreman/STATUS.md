# STATUS — 收口安装器、CI 与文档边界

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：241e7aa（T8）、39746d8（T9）、5e5b35c（T10）；本 STATUS 随后单独提交

## T8 安装器保护已有 notify-lead — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ bash tests/test-install.sh
  [8] 安装时保护改过的 notify-lead
    ✅ 默认安装退出码为 0
    ✅ 默认安装保留用户 notify-lead
    ✅ 输出保留提示
    ✅ --force 安装退出码为 0
    ✅ --force 装入仓库版本
    ✅ 备份内容与用户原版本一致
  ...
  PASS=33 FAIL=0
  ```
  用例在临时 HOME 预置内容为 `USER NOTIFY` 的 `~/.local/bin/notify-lead`：
  默认安装后 `cmp` 确认文件内容未变，并输出“内容与仓库不同 —— 留着”；
  同一夹具 `--force` 后 `cmp` 确认装入仓库版本，且 `notify-lead.bak-*`
  与预置内容完全一致。

- **AC2 [命令]**: ✅
  ```
  $ bash -n install.sh
  退出码=0
  ```

- **AC3 [命令]**: ✅
  ```
  $ bash tests/test-install.sh
  ...
  PASS=33 FAIL=0
  ```

- **改动**：`install.sh`、`tests/test-install.sh`
- **提交**：`241e7aa`
- **边界核对**：
  - 未改 uninstall 的“内容不同就留着”逻辑。
  - 测试全部在临时 HOME 里，不读写真实 HOME。
  - `--force` 用 `mktemp` 生成唯一 `notify-lead.bak-*`；同一秒重复执行也不会覆盖已有备份。
- **备注**：新计划 T8-T10；T8 无依赖。

---

## T9 将文档链接检查纳入 CI — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rg -n 'python3 scripts/check-links\.py' .github/workflows/ci.yml
  19:          python3 scripts/check-links.py
  ```

- **AC2 [命令]**: ✅
  ```
  $ python3 scripts/check-links.py
  链接检查通过：26 个本地链接/锚点
  ```

- **AC3 [命令]**: ✅
  ```
  $ ./scripts/foreman-check.sh && bash tests/test-foreman-check.sh && \
      bash tests/test-install.sh && bash tests/test-notify-lead.sh && \
      python3 scripts/check-links.py
  foreman-check: 通过
  PASS=7 FAIL=0
  PASS=33 FAIL=0
  PASS=24 FAIL=0
  链接检查通过：26 个本地链接/锚点
  退出码=0
  ```

- **AC4 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **改动**：`.github/workflows/ci.yml`
- **提交**：`39746d8`
- **边界核对**：四个既有回归命令保留；只增加链接检查，未改 `scripts/check-links.py` 的校验范围。
- **备注**：T8 审查 PASS（`12e9241`），本任务在其后执行。

---

## T10 修正文档中的过时和不准确描述 — 状态：DONE

- **AC1 [命令]**: ✅
  ```
  $ rg -n '零依赖|zero dependencies|逐字节还原|byte-for-byte' README.md README.en.md
  （无输出；rg 退出码 1 = 没有匹配）
  ```
  已改为“无额外包依赖 / 无常驻服务”；卸载描述与实际换行行为一致
  （原文件末尾没有换行时会补一个）。

- **AC2 [命令]**: ✅
  ```
  $ rg -n '期二（钩子）未做' docs/showcase.html
  （无输出；rg 退出码 1 = 没有匹配）
  ```

- **AC3 [命令]**: ✅
  ```
  $ rg -n 'docs/(showcase|what-it-is-for)\.html' README.md README.en.md
  README.en.md:14:> See it in action: <a href="docs/showcase.html">showcase</a> · <a href="docs/what-it-is-for.html">what it is for</a>
  README.md:13:> 看效果：<a href="docs/showcase.html">项目展示</a> · <a href="docs/what-it-is-for.html">它解决什么问题</a>
  ```
  项目状态清单（`README.md:347-349` / `README.en.md:391-393`）列出
  `foreman-check`、`tests/`、CI、`--status`；`README.en.md:377` 明确说明
  详细契约与设计文档目前只有中文。

- **AC4 [命令]**: ✅
  ```
  $ python3 scripts/check-links.py
  链接检查通过：26 个本地链接/锚点
  ```

- **AC5 [命令]**: ✅
  ```
  $ git diff --check
  退出码=0
  ```

- **改动**：`README.md`、`README.en.md`、`docs/showcase.html`、`docs/architecture.md`
- **提交**：`5e5b35c`
- **边界核对**：未改 T1 确立的角色边界/额度闸门；未重写与这些准确性问题无关的定位描述。
- **备注**：T9 审查 PASS（`39af72b`），本任务在其后执行。
- **说明**：README 里的两个展示页链接用 HTML `<a>`，链接检查器的 Markdown 计数保持 26；
  HTML 链接在 GitHub 正常渲染。完整回归链
  `foreman-check → 7 → 33 → 24 → 26` 退出码 0。
