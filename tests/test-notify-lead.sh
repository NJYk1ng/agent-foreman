#!/usr/bin/env bash
#
# notify-lead.sh 的回归测试。所有数据库和 HOME 都在临时目录里，不碰真实会话库。
#
# 覆盖：
#   1. 默认只选交互式会话，跳过 codex_exec / subagent
#   2. --thread 显式选会话，且不依赖数据库
#   3. 项目路径是符号链接时按真实路径匹配
#   4. 没有交互式会话：退出码 12
#   5. schema 不兼容：退出码 11
#   6. 会话库缺失：退出码 10
#   7. python3 缺失：退出码 5
#   8. 语法检查
#
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO/scripts/notify-lead.sh"
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

BIN="$T/bin"
BASH_BIN="$(command -v bash)"
mkdir -p "$BIN" "$T/home"
CAPTURE="$T/capture"
export CAPTURE
cat > "$BIN/codex" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CAPTURE"
SH
chmod +x "$BIN/codex"

make_db() {   # make_db <db> <sql>
    python3 - "$1" "$2" <<'PY'
import sqlite3, sys
db, sql = sys.argv[1], sys.argv[2]
con = sqlite3.connect(db)
con.execute("""CREATE TABLE threads (
    id TEXT, cwd TEXT, source TEXT, thread_source TEXT, originator TEXT,
    archived INTEGER, created_at_ms INTEGER, updated_at_ms INTEGER,
    recency_at_ms INTEGER, name TEXT)""")
con.executescript(sql)
con.commit()
con.close()
PY
}

make_old_db() {   # 故意缺 archived 列，模拟 schema 升级
    python3 - "$1" <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.execute("""CREATE TABLE threads (
    id TEXT, cwd TEXT, source TEXT, thread_source TEXT, originator TEXT,
    created_at_ms INTEGER, updated_at_ms INTEGER, recency_at_ms INTEGER, name TEXT)""")
con.commit()
con.close()
PY
}

run_notify() {   # run_notify <project> <codex_home> <path> [args...]
    local proj="$1" codex_home="$2" path="$3"; shift 3
    : > "$CAPTURE"
    ( cd "$proj" && HOME="$T/home" CODEX_HOME="$codex_home" PATH="$path" \
        "$BASH_BIN" "$SCRIPT" "$@" 2>&1 )
}

# ── 1. 默认只选交互式会话 ───────────────────────────────────
printf '\n[1] 默认只选交互式会话\n'
proj="$T/proj1"
mkdir -p "$proj/.foreman"
dbdir="$T/db1"
mkdir -p "$dbdir"
make_db "$dbdir/state_5.sqlite" "
INSERT INTO threads VALUES ('subagent-new','$proj','{\"subagent\":\"review\"}','subagent','Codex Desktop',0,300,300,300,'review');
INSERT INTO threads VALUES ('exec-newer','$proj','exec','user','codex_exec',0,200,200,200,NULL);
INSERT INTO threads VALUES ('interactive','$proj','vscode','user','Codex Desktop',0,100,100,100,'main');
"
out="$(run_notify "$proj" "$dbdir" "$BIN:$PATH")"; rc=$?
assert_eq "退出码为 0" "0" "$rc"
if grep -q -- '--thread interactive' "$CAPTURE"; then
    ok "选中交互式会话"
else
    bad "没有选中交互式会话"
fi
if ! grep -q -- '--thread subagent-new' "$CAPTURE"; then
    ok "跳过 subagent"
else
    bad "选中了 subagent"
fi
if ! grep -q -- '--thread exec-newer' "$CAPTURE"; then
    ok "跳过 codex_exec"
else
    bad "选中了 codex_exec"
fi

# ── 2. --thread 显式选会话（不依赖数据库） ──────────────────
printf '\n[2] --thread 显式选会话\n'
proj="$T/proj2"
mkdir -p "$proj/.foreman"
empty="$T/empty-db"
mkdir -p "$empty"
out="$(run_notify "$proj" "$empty" "$BIN:$PATH" --thread chosen-id "hello")"; rc=$?
assert_eq "退出码为 0" "0" "$rc"
if grep -q -- '--thread chosen-id' "$CAPTURE"; then
    ok "使用显式会话"
else
    bad "没有使用显式会话"
fi

# ── 3. 符号链接项目路径 ─────────────────────────────────────
printf '\n[3] 符号链接项目路径\n'
real="$T/realproj"
mkdir -p "$real/.foreman"
link="$T/linkproj"
ln -s "$real" "$link"
dbdir="$T/db3"
mkdir -p "$dbdir"
make_db "$dbdir/state_5.sqlite" "
INSERT INTO threads VALUES ('symlink-thread','$link','vscode','user','Codex Desktop',0,100,100,100,'main');
"
out="$(run_notify "$link" "$dbdir" "$BIN:$PATH")"; rc=$?
assert_eq "退出码为 0" "0" "$rc"
if grep -q -- '--thread symlink-thread' "$CAPTURE"; then
    ok "symlink 路径按真实路径匹配"
else
    bad "symlink 路径没有匹配"
fi

# ── 4. 没有交互式会话 ───────────────────────────────────────
printf '\n[4] 没有交互式会话\n'
proj="$T/proj4"
mkdir -p "$proj/.foreman"
dbdir="$T/db4"
mkdir -p "$dbdir"
make_db "$dbdir/state_5.sqlite" "
INSERT INTO threads VALUES ('exec-only','$proj','exec','user','codex_exec',0,200,200,200,NULL);
INSERT INTO threads VALUES ('subagent-only','$proj','{\"subagent\":\"review\"}','subagent','Codex Desktop',0,100,100,100,'review');
"
out="$(run_notify "$proj" "$dbdir" "$BIN:$PATH")"; rc=$?
assert_eq "退出码为 12" "12" "$rc"
case "$out" in
    *"没有可用的交互式"*) ok "错误信息说明没有交互式会话" ;;
    *) bad "错误信息不对" ;;
esac

# ── 5. schema 不兼容 ────────────────────────────────────────
printf '\n[5] schema 不兼容\n'
proj="$T/proj5"
mkdir -p "$proj/.foreman"
dbdir="$T/db5"
mkdir -p "$dbdir"
make_old_db "$dbdir/state_5.sqlite"
out="$(run_notify "$proj" "$dbdir" "$BIN:$PATH")"; rc=$?
assert_eq "退出码为 11" "11" "$rc"
case "$out" in
    *"schema"*) ok "错误信息说明 schema 不一致" ;;
    *) bad "错误信息不对" ;;
esac

# ── 6. 会话库缺失 ───────────────────────────────────────────
printf '\n[6] 会话库缺失\n'
proj="$T/proj6"
mkdir -p "$proj/.foreman"
empty="$T/no-db"
mkdir -p "$empty"
out="$(run_notify "$proj" "$empty" "$BIN:$PATH")"; rc=$?
assert_eq "退出码为 10" "10" "$rc"
case "$out" in
    *"会话库"*) ok "错误信息说明会话库缺失" ;;
    *) bad "错误信息不对" ;;
esac

# ── 7. python3 缺失 ─────────────────────────────────────────
printf '\n[7] python3 缺失\n'
proj="$T/proj7"
mkdir -p "$proj/.foreman"
minbin="$T/minbin"
mkdir -p "$minbin"
ln -s "$(command -v dirname)" "$minbin/dirname"
ln -s "$BIN/codex" "$minbin/codex"
out="$(run_notify "$proj" "$T/no-db" "$minbin")"; rc=$?
assert_eq "退出码为 5" "5" "$rc"
case "$out" in
    *"python3"*) ok "错误信息说明需要 python3" ;;
    *) bad "错误信息不对" ;;
esac

# ── 8. 语法检查 ─────────────────────────────────────────────
printf '\n[8] 语法检查\n'
if bash -n "$SCRIPT"; then
    ok "bash -n notify-lead.sh"
else
    bad "notify-lead.sh 语法错误"
fi

printf '\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
