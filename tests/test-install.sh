#!/usr/bin/env bash
#
# install.sh 的回归测试。所有用例都在临时 HOME 里跑，不碰真实用户目录。
#
# 覆盖：
#   1. 全局文件有开始标记、缺结束标记时，--uninstall 必须失败且文件逐字节不变
#   2. 默认安装保留用户改过的同名 skill；--force 覆盖前生成可恢复的备份
#   3. 项目里已有 AGENTS.md 时，冲突提示不能用自引用 @AGENTS.md
#   4. 正常卸载不得删除标记段之外的内容
#   5. install.sh 语法检查
#
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

PASS=0
FAIL=0
ok()  { printf '  ✅ %s\n' "$*"; PASS=$((PASS + 1)); }
bad() { printf '  ❌ %s\n' "$*"; FAIL=$((FAIL + 1)); }

assert_eq() {   # assert_eq <说明> <期望> <实际>
    if [ "$2" = "$3" ]; then
        ok "$1"
    else
        bad "$1（期望 [$2]，实际 [$3]）"
    fi
}

mk_home() {   # mk_home <名字> → 打印一个隔离的 HOME
    local h="$T/$1"
    mkdir -p "$h/.claude" "$h/.codex" "$h/.local/bin"
    printf '%s\n' "$h"
}

run_install() {   # run_install <HOME> [install.sh 参数...]
    local h="$1"; shift
    HOME="$h" \
    CLAUDE_SKILLS_DIR="$h/.claude/skills" \
    CODEX_SKILLS_DIR="$h/.codex/skills" \
    FOREMAN_BIN_DIR="$h/.local/bin" \
    CODEX_HOME="$h/.codex" \
    "$REPO/install.sh" "$@"
}

# ── 1. 缺结束标记：拒绝卸载，文件逐字节不变 ─────────────────
printf '\n[1] 缺结束标记\n'
h="$(mk_home missing-end)"
printf '# user rules\n' > "$h/.claude/CLAUDE.md"
run_install "$h" >/dev/null 2>&1
python3 - "$h/.claude/CLAUDE.md" <<'PY'
import sys
p = sys.argv[1]
lines = [ln for ln in open(p, encoding="utf-8") if "agent-foreman 结束" not in ln]
open(p, "w", encoding="utf-8").writelines(lines)
PY
cp "$h/.claude/CLAUDE.md" "$T/missing-end-before"
out="$(run_install "$h" --uninstall 2>&1)"; rc=$?
assert_eq "退出码为 3" "3" "$rc"
if cmp -s "$T/missing-end-before" "$h/.claude/CLAUDE.md"; then
    ok "目标文件逐字节不变"
else
    bad "目标文件被修改"
fi
case "$out" in
    *"结束标记"*) ok "错误信息说明结束标记缺失" ;;
    *) bad "错误信息没有说明结束标记缺失" ;;
esac

# ── 2. 标记错序：孤立结束标记在前、开始标记在后 ─────────────
printf '\n[2] 标记错序\n'
h="$(mk_home marker-order)"
{
    printf 'KEEP-BEFORE\n'
    printf '<!-- ═══ agent-foreman 结束 ═══ -->\n'
    printf 'KEEP-AFTER\n'
    printf '<!-- ═══ agent-foreman 开始 · test ═══ -->\n'
    printf 'SENTINEL-TAIL\n'
} > "$h/.claude/CLAUDE.md"
cp "$h/.claude/CLAUDE.md" "$T/marker-order-before"

out="$(run_install "$h" --uninstall 2>&1)"; rc=$?
assert_eq "错序标记退出码为 3" "3" "$rc"
if cmp -s "$T/marker-order-before" "$h/.claude/CLAUDE.md"; then
    ok "错序标记文件逐字节不变"
else
    bad "错序标记文件被修改"
fi
case "$out" in
    *"不成对"*) ok "错误信息说明标记不成对" ;;
    *) bad "错误信息没有说明标记不成对" ;;
esac

# ── 3. 同名 skill：默认保留用户版本；--force 先备份 ──────────
printf '\n[3] 默认安装 / --force 备份\n'
h="$(mk_home skill-backup)"
mkdir -p "$h/.claude/skills/agent-contract"
printf 'USER VERSION\n' > "$h/.claude/skills/agent-contract/SKILL.md"
cp -a "$h/.claude/skills/agent-contract" "$T/user-agent-contract"

out="$(run_install "$h" 2>&1)"; rc=$?
assert_eq "默认安装退出码为 0" "0" "$rc"
if grep -q 'USER VERSION' "$h/.claude/skills/agent-contract/SKILL.md"; then
    ok "默认安装保留用户版本"
else
    bad "默认安装覆盖了用户版本"
fi

out="$(run_install "$h" --force 2>&1)"; rc=$?
assert_eq "--force 安装退出码为 0" "0" "$rc"
if cmp -s "$REPO/skills/agent-contract/SKILL.md" "$h/.claude/skills/agent-contract/SKILL.md"; then
    ok "--force 装入仓库版本"
else
    bad "--force 没有装入仓库版本"
fi
bak="$(ls -d "$h/.claude/skills/agent-contract.bak-"* 2>/dev/null | head -n1)"
if [ -n "$bak" ] && cmp -s "$T/user-agent-contract/SKILL.md" "$bak/SKILL.md"; then
    ok "备份内容与用户原版本一致"
else
    bad "没有可恢复的备份（或备份内容不对）"
fi

# ── 4. 项目 AGENTS.md 冲突：提示可用，不自引用 ──────────────
printf '\n[4] 项目文件冲突\n'
h="$(mk_home project)"
proj="$T/proj"
mkdir -p "$proj"
printf '# user agents\n' > "$proj/AGENTS.md"
printf '# user claude\n' > "$proj/CLAUDE.md"
cp "$proj/AGENTS.md" "$T/proj-agents-before"

out="$(run_install "$h" --project "$proj" 2>&1)"; rc=$?
assert_eq "项目安装退出码为 0" "0" "$rc"
case "$out" in
    *"手工合并"*"不要加 @AGENTS.md"*) ok "AGENTS.md 冲突提示可用且不自引用" ;;
    *) bad "AGENTS.md 冲突提示不可用" ;;
esac
if cmp -s "$T/proj-agents-before" "$proj/AGENTS.md"; then
    ok "默认不覆盖用户 AGENTS.md"
else
    bad "默认覆盖了用户 AGENTS.md"
fi

out="$(run_install "$h" --project "$proj" --force 2>&1)"; rc=$?
assert_eq "项目 --force 退出码为 0" "0" "$rc"
bak="$(ls "$proj/AGENTS.md.bak-"* 2>/dev/null | head -n1)"
if [ -n "$bak" ] && cmp -s "$T/proj-agents-before" "$bak"; then
    ok "项目 --force 覆盖前备份了原文件"
else
    bad "项目 --force 没有可恢复的备份"
fi

# ── 5. 正常卸载：标记段之外的内容必须保留 ───────────────────
printf '\n[5] 正常卸载保留外部内容\n'
h="$(mk_home uninstall-normal)"
printf '# user top\nSENTINEL-TOP\n' > "$h/.claude/CLAUDE.md"
run_install "$h" >/dev/null 2>&1
printf 'SENTINEL-AFTER\n' >> "$h/.claude/CLAUDE.md"

out="$(run_install "$h" --uninstall 2>&1)"; rc=$?
assert_eq "正常卸载退出码为 0" "0" "$rc"
if grep -q 'SENTINEL-TOP' "$h/.claude/CLAUDE.md" && grep -q 'SENTINEL-AFTER' "$h/.claude/CLAUDE.md"; then
    ok "标记段前后的内容都保留"
else
    bad "标记段之外的内容被删除"
fi
if ! grep -q 'agent-foreman 开始' "$h/.claude/CLAUDE.md"; then
    ok "标记段已删除"
else
    bad "标记段没有被删除"
fi

# ── 6. 全局文件是符号链接：写真实目标，不破坏链接 ───────────
printf '\n[6] 符号链接的全局文件\n'
h="$(mk_home symlink)"
real="$T/real-Claude.md"
printf '# real rules\nKEEP\n' > "$real"
ln -s "$real" "$h/.claude/CLAUDE.md"

run_install "$h" >/dev/null 2>&1; rc=$?
assert_eq "安装退出码为 0" "0" "$rc"
if [ -L "$h/.claude/CLAUDE.md" ] && grep -q 'agent-foreman 开始' "$real"; then
    ok "符号链接保留，真实文件写入"
else
    bad "符号链接被破坏或真实文件没写入"
fi

run_install "$h" --uninstall >/dev/null 2>&1; rc=$?
assert_eq "卸载退出码为 0" "0" "$rc"
if [ -L "$h/.claude/CLAUDE.md" ] && grep -q 'KEEP' "$real" && ! grep -q 'agent-foreman 开始' "$real"; then
    ok "卸载后符号链接和用户内容都保留"
else
    bad "卸载破坏了符号链接或用户内容"
fi

# ── 7. 用户改过的 notify-lead：卸载必须留着 ─────────────────
printf '\n[7] 用户改过的 notify-lead\n'
h="$(mk_home notify-lead)"
run_install "$h" >/dev/null 2>&1
printf '# user edit\n' >> "$h/.local/bin/notify-lead"
out="$(run_install "$h" --uninstall 2>&1)"; rc=$?
assert_eq "卸载退出码为 0" "0" "$rc"
if [ -e "$h/.local/bin/notify-lead" ] && grep -q 'user edit' "$h/.local/bin/notify-lead"; then
    ok "用户改过的 notify-lead 没被删除"
else
    bad "用户改过的 notify-lead 被删除"
fi

# ── 8. 语法检查 ─────────────────────────────────────────────
printf '\n[8] 语法检查\n'
if bash -n "$REPO/install.sh"; then
    ok "bash -n install.sh"
else
    bad "install.sh 语法错误"
fi

printf '\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
