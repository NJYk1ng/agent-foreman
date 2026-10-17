# STATUS — 收口安装器、CI 与文档边界

> 工人：Claude Code (deepseek-flash) · 2026-10-17 · 提交：241e7aa（T8 实现；本 STATUS 随后单独提交）

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
