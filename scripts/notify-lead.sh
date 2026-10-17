#!/usr/bin/env bash
#
# notify-lead.sh — 通知领导（Codex）：这个项目该你干活了。
#
# 干什么：找到本项目最近的【交互式】Codex 会话 → 往它里面塞一条消息 → Codex 自己醒。
#
# ⭐ 为什么这么写：
#   Codex 没有「文件变了就开一轮」的能力（它的 inotify 只盯配置类文件，
#   钩子事件里也没有 FileChanged）。但它有一条别的路 ——
#   `codex queue --thread <会话> --message <文本>`，
#   能从外面把消息塞进一个正在运行的会话里。实测有效：
#   TUI 停在提示符上时塞消息，它会自己开一轮。
#
# ⭐ 只选交互式会话。
#   实测 Codex 的 threads 表里还有两类不是活 TUI 的线程：
#     - codex_exec：source='exec' / originator='codex_exec'
#     - subagent  ：thread_source='subagent' / source='{"subagent":...}'
#   （review 的 Guardian 线程就是后者。）`codex queue` 塞进去不会有人读。
#   所以默认过滤掉；需要精确指定时用 --thread <id>。
#
# ⭐ 这条命令不会让 Codex 直接开干。
#   真正管住额度的是 AGENTS.md 里那条规矩：被叫醒时先问人。
#
# 用法：
#   notify-lead                          # 在项目里任意位置跑，用默认消息
#   notify-lead "自定义消息"              # 改消息
#   notify-lead "消息" /path/to/project   # 显式指定项目
#   notify-lead --thread <id> "消息"      # 显式指定会话（跳过数据库查询）
#
set -uo pipefail

SCRIPT_NAME="notify-lead"
THREAD=""
MSG=""
PROJ_ARG=""

usage() {
    cat <<'EOF'
notify-lead — 通知领导（Codex）：这个项目该你干活了。

用法：
  notify-lead                          # 在项目里任意位置跑，用默认消息
  notify-lead "自定义消息"              # 改消息
  notify-lead "消息" /path/to/project   # 显式指定项目
  notify-lead --thread <id> "消息"      # 显式指定会话（跳过数据库查询）
EOF
}

add_positional() {
    if [ -z "$MSG" ]; then
        MSG="$1"
    elif [ -z "$PROJ_ARG" ]; then
        PROJ_ARG="$1"
    else
        printf '%s: 多余参数：%s\n' "$SCRIPT_NAME" "$1" >&2
        exit 2
    fi
}

while [ $# -gt 0 ]; do
    case "$1" in
        --thread)
            shift
            [ $# -gt 0 ] || { printf '%s: --thread 后面要跟会话 ID\n' "$SCRIPT_NAME" >&2; exit 2; }
            THREAD="$1"
            ;;
        --thread=*)
            THREAD="${1#--thread=}"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while [ $# -gt 0 ]; do add_positional "$1"; shift; done
            break
            ;;
        -*)
            printf '%s: 未知参数 %s（试 --help）\n' "$SCRIPT_NAME" "$1" >&2
            exit 2
            ;;
        *)
            add_positional "$1"
            ;;
    esac
    shift
done

MSG="${MSG:-工人交活了。读 .foreman/ 看该你干什么。⭐ 先问人一句要不要现在干，得到同意再动手。}"

# ── 找项目根 ─────────────────────────────────────────────────
# ⭐ 全局安装：从 $PWD 往上找有 .foreman/ 的那一层。
#    这样脚本装在哪都行（默认 ~/.local/bin/notify-lead），
#    **装一次，所有项目都能用，新项目零配置。**
#    第二个位置参数可以显式指定项目目录，一般用不着。
PROJ="$(cd "${PROJ_ARG:-$PWD}" 2>/dev/null && pwd)" || {
    printf '%s: 目录不存在：%s\n' "$SCRIPT_NAME" "${PROJ_ARG:-$PWD}" >&2; exit 2
}
d="$PROJ"
while [ "$d" != "/" ] && [ ! -d "$d/.foreman" ]; do d="$(dirname "$d")"; done
if [ ! -d "$d/.foreman" ]; then
    printf '%s: 从 %s 往上都没找到 .foreman/ —— 这不像是个 agent-foreman 项目。\n' "$SCRIPT_NAME" "$PROJ" >&2
    exit 1
fi
PROJ="$d"

# ── 选会话 ───────────────────────────────────────────────────
if [ -n "$THREAD" ]; then
    TID="$THREAD"
    printf '%s: 使用显式会话 %s\n' "$SCRIPT_NAME" "$TID"
else
    if ! command -v python3 >/dev/null 2>&1; then
        printf '%s: 需要 python3 才能读取 Codex 会话库。\n' "$SCRIPT_NAME" >&2
        printf '            装好 python3 后重试，或用 --thread <id> 显式指定会话。\n' >&2
        exit 5
    fi

    TID="$(python3 - "$PROJ" <<'PY'
import glob, os, re, sqlite3, sys

# ⚠️ 两个都别写死：
#   ① 家目录 —— 设了 CODEX_HOME 的人（很常见）会在别处；
#   ② 文件名里的版本号 —— `state_5.sqlite` 的 5 是 Codex 的 schema 版本，
#      写死在 Codex 二进制里。它哪天升到 state_6，写死的路径就找不到了。
#      ⇒ 按版本号找最大的那个。
codex_home = os.environ.get("CODEX_HOME") or os.path.expanduser("~/.codex")
cands = glob.glob(os.path.join(codex_home, "state_*.sqlite"))
def ver(p):
    m = re.search(r"state_(\d+)\.sqlite$", p)
    return int(m.group(1)) if m else -1
cands = [c for c in cands if ver(c) >= 0]
if not cands:
    sys.stderr.write(
        f"notify-lead: 没找到 Codex 会话库（{codex_home}/state_*.sqlite）。\n"
        "            先在这个目录开一次 codex（并说一句话把会话建出来），"
        "或用 --thread <id> 显式指定。\n"
    )
    sys.exit(10)
db = max(cands, key=ver)
proj = os.path.realpath(sys.argv[1])

# 只选交互式会话：
#   codex_exec        → source='exec' / originator='codex_exec'
#   review subagent   → source='{"subagent":...}' / thread_source='subagent'
# 这些都不是活着的 TUI，queue 进去不会有人读。
def is_interactive(source, thread_source, originator):
    source = source or ""
    thread_source = thread_source or "user"
    originator = originator or ""
    if thread_source == "subagent":
        return False
    if '"subagent"' in source:
        return False
    if source in ("exec", "subagent", "codex_exec"):
        return False
    if originator in ("codex_exec", "codex-exec"):
        return False
    return True

try:
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    rows = con.execute(
        "SELECT id, cwd, COALESCE(source,''), COALESCE(thread_source,'user'), "
        "COALESCE(originator,''), COALESCE(archived,0) FROM threads "
        "ORDER BY COALESCE(recency_at_ms, updated_at_ms, created_at_ms) DESC"
    ).fetchall()
    con.close()
except sqlite3.Error as e:
    sys.stderr.write(
        f"notify-lead: Codex 会话库 schema 与脚本预期不一致（Codex 可能升级了）：{e}\n"
        f"            库文件：{db}\n"
        "            可以先用 --thread <id> 显式指定会话；"
        "或把这条报错发到项目 issue。\n"
    )
    sys.exit(11)

skipped = 0
for tid, cwd, source, thread_source, originator, archived in rows:
    if archived or not cwd:
        continue
    if os.path.realpath(cwd) != proj:
        continue
    if not is_interactive(source, thread_source, originator):
        skipped += 1
        continue
    print(tid)
    break
else:
    sys.stderr.write(
        f"notify-lead: 项目 {proj} 没有可用的交互式 Codex 会话。\n"
        f"            已跳过 {skipped} 条 codex_exec / subagent 线程。\n"
        "            先在这个目录打开 codex（CLI 或桌面版）并建一个会话；\n"
        "            或确认会话的 cwd 是项目根，然后用 --thread <id> 显式指定。\n"
    )
    sys.exit(12)
PY
)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        exit "$rc"
    fi
fi

if [ -z "$TID" ]; then
    printf '%s: 没有选中任何会话。\n' "$SCRIPT_NAME" >&2
    exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
    printf '%s: 没找到 codex 命令（需要带 codex queue 的版本）。\n' "$SCRIPT_NAME" >&2
    exit 7
fi

printf '%s: 正在推给会话 %s\n' "$SCRIPT_NAME" "$TID"
if ! codex queue --thread "$TID" --message "$MSG"; then
    printf '%s: 推给会话 %s 失败。\n' "$SCRIPT_NAME" "$TID" >&2
    exit 8
fi
