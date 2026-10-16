#!/usr/bin/env bash
#
# notify-lead.sh — 通知领导（Codex）：这个项目该你干活了。
#
# 干什么：找到本项目最近的 Codex 会话 → 往它里面塞一条消息 → Codex 自己醒。
#
# ⭐ 为什么这么写：
#   Codex 没有「文件变了就开一轮」的能力（它的 inotify 只盯配置类文件，
#   钩子事件里也没有 FileChanged）。但它有一条别的路 ——
#   `codex queue --thread <会话> --message <文本>`，
#   能从外面把消息塞进一个正在运行的会话里。实测有效：
#   TUI 停在提示符上时塞消息，它会自己开一轮。
#
# ⭐ 这条命令不会让 Codex 直接开干。
#   真正管住额度的是 AGENTS.md 里那条规矩：被叫醒时先问人。
#
# 用法：
#   bash .foreman/notify-lead.sh              # 用默认消息
#   bash .foreman/notify-lead.sh "自定义消息"  # 改消息
#   bash .foreman/notify-lead.sh "消息" /path/to/project
#
set -uo pipefail

MSG="${1:-工人交活了。读 .foreman/ 看该你干什么。⭐ 先问人一句要不要现在干，得到同意再动手。}"

# ⭐ 项目根按【脚本自己的位置】推 —— 脚本住在 <项目>/.foreman/ 里，
#    所以上两级就是项目根。比用 $PWD 稳：调用方 cd 到哪儿都不影响。
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="${2:-$(dirname "$SELF")}"

PROJ="$(cd "$PROJ" 2>/dev/null && pwd)" || {
    echo "notify-lead: 目录不存在：${2:-$PWD}" >&2; exit 2
}

# ── 找本项目最近的、没归档的 Codex 会话 ──────────────────────
# ⚠️ threads.cwd 里有的带前导斜杠、有的不带（实测同一个项目两种形式并存：
#    /path/to/proj 和 path/to/proj）⇒ 两种都要匹配。
TID="$(python3 - "$PROJ" <<'PY'
import os, sqlite3, sys
# ⚠️ 别写死 ~/.codex —— 设了 CODEX_HOME 的人（很常见）会找不到库，
#    然后这里静默返回空 → 上层报"没找到会话"，看起来像"你没开 Codex"，其实是路径不对。
codex_home = os.environ.get("CODEX_HOME") or os.path.expanduser("~/.codex")
db = os.path.join(codex_home, "state_5.sqlite")
if not os.path.exists(db):
    sys.exit(0)
proj = os.path.realpath(sys.argv[1])
con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
row = con.execute(
    "SELECT id, COALESCE(name,'') FROM threads "
    "WHERE cwd IN (?, ?) AND COALESCE(archived, 0) = 0 "
    "ORDER BY COALESCE(recency_at_ms, updated_at_ms, created_at_ms) DESC LIMIT 1",
    (proj, proj.lstrip("/")),
).fetchone()
con.close()
if row:
    print(row[0])
PY
)"

if [ -z "$TID" ]; then
    echo "notify-lead: 在 $PROJ 里没找到 Codex 会话。" >&2
    echo "            先在那个目录开一次 codex（并说一句话把会话建出来），再通知。" >&2
    exit 1
fi

echo "notify-lead: 推给会话 $TID"
codex queue --thread "$TID" --message "$MSG"
