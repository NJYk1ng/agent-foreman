#!/usr/bin/env bash
#
# foreman-check.sh 的负向回归：
#   1. 合法夹具 → 0
#   2. 计划缺字段 → 非 0，指出任务/字段
#   3. 模板缺停工护栏 → 非 0，指出文件
#   4. 脚本语法错误 → 非 0，指出文件
#
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

PASS=0
FAIL=0
ok()  { printf '  ✅ %s\n' "$*"; PASS=$((PASS + 1)); }
bad() { printf '  ❌ %s\n' "$*"; FAIL=$((FAIL + 1)); }

ROOT="$T/root"

copy_fixture() {
    rm -rf "$ROOT"
    mkdir -p "$ROOT/.foreman" "$ROOT/templates" "$ROOT/skills/execute-plan" "$ROOT/scripts"
    cp "$REPO/.foreman/PLAN.md" "$ROOT/.foreman/"
    cp "$REPO/templates/AGENTS.md" "$REPO/templates/global-claude.md" "$ROOT/templates/"
    cp "$REPO/skills/execute-plan/SKILL.md" "$ROOT/skills/execute-plan/"
    cp "$REPO/install.sh" "$ROOT/"
    cp "$REPO/scripts/notify-lead.sh" "$REPO/scripts/foreman-check.sh" \
       "$REPO/scripts/check-links.py" "$ROOT/scripts/"
}

run_check() {
    bash "$REPO/scripts/foreman-check.sh" --root "$ROOT" 2>&1
}

# ── 1. 合法夹具 ─────────────────────────────────────────────
printf '\n[1] 合法夹具\n'
copy_fixture
out="$(run_check)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'foreman-check: 通过'; then
    ok "合法夹具通过"
else
    bad "合法夹具没有通过（exit=$rc）"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ── 2. 计划缺字段 ───────────────────────────────────────────
printf '\n[2] 计划缺字段\n'
copy_fixture
python3 - "$ROOT/.foreman/PLAN.md" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().splitlines()
out, in_t1 = [], False
for ln in lines:
    if ln.startswith("### T1"):
        in_t1 = True
    elif ln.startswith("### T") or ln.startswith("## "):
        in_t1 = False
    if in_t1 and "**边界**" in ln:
        continue
    out.append(ln)
open(p, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
out="$(run_check)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q '边界'; then
    ok "缺字段被拒绝并指出「边界」"
else
    bad "缺字段没有被正确报告（exit=$rc）"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ── 3. 模板缺停工护栏 ───────────────────────────────────────
printf '\n[3] 模板缺停工护栏\n'
copy_fixture
python3 - "$ROOT/templates/AGENTS.md" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().splitlines()
out = [ln for ln in lines if "没有 .foreman/PLAN.md" not in ln]
open(p, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
out="$(run_check)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'AGENTS.md'; then
    ok "缺护栏被拒绝并指出 AGENTS.md"
else
    bad "缺护栏没有被正确报告（exit=$rc）"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ── 4. 脚本语法错误 ─────────────────────────────────────────
printf '\n[4] 脚本语法错误\n'
copy_fixture
printf '\nif\n' >> "$ROOT/install.sh"
out="$(run_check)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'install.sh'; then
    ok "语法错误被拒绝并指出 install.sh"
else
    bad "语法错误没有被正确报告（exit=$rc）"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ── 5. 字段值为空 ───────────────────────────────────────────
printf '\n[5] 字段值为空\n'
copy_fixture
python3 - "$ROOT/.foreman/PLAN.md" <<'PY'
import sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().splitlines()
out, in_t1 = [], False
for ln in lines:
    if ln.startswith("### T1"):
        in_t1 = True
    elif ln.startswith("### T") or ln.startswith("## "):
        in_t1 = False
    if in_t1 and ln.startswith("- **边界**"):
        ln = "- **边界**："
    out.append(ln)
open(p, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
out="$(run_check)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q '边界'; then
    ok "空字段值被拒绝并指出「边界」"
else
    bad "空字段值没有被正确报告（exit=$rc）"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

printf '\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
