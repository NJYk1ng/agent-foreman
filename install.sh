#!/usr/bin/env bash
#
# 把 agent-foreman 装起来。两件事：
#   ① 把 skill 装到各自该去的那一侧（全局）
#   ② 带 --project 时，把协作要用的文件放进那个项目
#
# 为什么 skill 要分着装：两个 harness 的 skill 格式是同一套（SKILL.md + name/description），
# 但【不自动同步】—— 实测：只放 `~/.claude/skills/` 的 skill，Codex 看不到，反之亦然。
#
# 用法：
#   ./install.sh                    只装 skill（全局）
#   ./install.sh --project <目录>   装 skill，并把协作文件放进那个项目
#   ./install.sh --dry-run          只说要做什么，不动文件
#   ./install.sh --uninstall        卸掉本仓库装的 skill
#   ./install.sh --force            覆盖已存在的
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"

CLAUDE_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_DIR="${CODEX_SKILLS_DIR:-${CODEX_HOME:-$HOME/.codex}/skills}"

# skill 名 : 装到哪几侧
LAYOUT="
agent-contract:claude,codex
execute-plan:claude
tech-lead:codex
cross-review:codex
"

DRY_RUN=0
FORCE=0
UNINSTALL=0
PROJECT=""
BACKUP_TS="$(date +%Y%m%d-%H%M%S)"

# 全局记忆的插入标记。开始标记只匹配前缀，结束标记要完整匹配。
AF_BEGIN='<!-- ═══ agent-foreman 开始'
AF_END='<!-- ═══ agent-foreman 结束 ═══ -->'

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)   DRY_RUN=1 ;;
        --force)     FORCE=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --project)
            shift
            PROJECT="${1:-}"
            [ -n "$PROJECT" ] || { printf 'install.sh: --project 后面要跟一个项目目录\n' >&2; exit 2; }
            ;;
        -h|--help)   sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'install.sh: 未知参数 %s（试 --help）\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

say()  { printf '  %s\n' "$*"; }
head_() { printf '\n%s\n' "$*"; }

target_dir() {
    case "$1" in
        claude) printf '%s' "$CLAUDE_DIR" ;;
        codex)  printf '%s' "$CODEX_DIR" ;;
        *)      printf 'install.sh: 未知目标侧 %s\n' "$1" >&2; exit 2 ;;
    esac
}

# 标记必须各恰好一个、且结束在开始之后。只有开始标记、没有结束标记，
# 或者结束标记出现在开始标记之前，都说明文件被改坏了；这时继续操作会把
# 用户文件后面的内容当成我们那段删掉 —— 所以直接拒绝。
check_global_marker_pair() {   # check_global_marker_pair <文件> <说明>
    local f="$1" what="$2"
    [ -e "$f" ] || return 0
    python3 - "$f" "$AF_BEGIN" "$AF_END" "$what" <<'PY'
import sys
path, begin, end_marker, what = sys.argv[1:5]
try:
    lines = open(path, encoding="utf-8").read().split("\n")
except OSError as e:
    sys.stderr.write(f"install.sh: 读不了 {what}：{path}（{e}）\n")
    sys.exit(1)
starts = [i for i, ln in enumerate(lines) if ln.startswith(begin)]
ends = [i for i, ln in enumerate(lines) if ln.strip() == end_marker]
if not starts and not ends:
    sys.exit(0)
if len(starts) == 1 and len(ends) == 1 and starts[0] < ends[0]:
    sys.exit(0)
sys.stderr.write(
    f"install.sh: {what} 里的 agent-foreman 标记不成对：{path}\n"
    f"            开始标记 {len(starts)} 个，结束标记 {len(ends)} 个；"
    "要求各恰好 1 个，且结束在开始之后。\n"
    "            拒绝安装/卸载/修改，文件保持原样。\n"
    f"            请从 {path}.bak-* 恢复，或手工修正标记。\n"
)
sys.exit(1)
PY
}

installed=0
skipped=0
removed=0

head_ "agent-foreman 安装器"
say "仓库    : $REPO_DIR"
say "Claude 侧: $CLAUDE_DIR"
say "Codex 侧 : $CODEX_DIR"
[ "$DRY_RUN" = 1 ]   && say "模式    : dry-run（不会动任何文件）"
[ "$UNINSTALL" = 1 ] && say "模式    : 卸载"

# ── Preflight：标记不成对就什么都别动 ──────────────────────
check_global_marker_pair "$HOME/.claude/CLAUDE.md"               "Claude Code 全局记忆" || exit 3
check_global_marker_pair "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "Codex 全局记忆"       || exit 3

for line in $LAYOUT; do
    [ -n "$line" ] || continue
    name="${line%%:*}"
    sides="${line#*:}"
    src="$SKILLS_SRC/$name"

    if [ ! -f "$src/SKILL.md" ]; then
        say "⚠️  跳过 $name —— 仓库里没有 $src/SKILL.md"
        continue
    fi

    IFS=',' read -r -a side_list <<< "$sides"
    for side in "${side_list[@]}"; do
        dest_root="$(target_dir "$side")"
        dest="$dest_root/$name"

        if [ "$UNINSTALL" = 1 ]; then
            if [ -d "$dest" ]; then
                if ! diff -rq "$src" "$dest" >/dev/null 2>&1; then
                    say "[$side] ⏭  $name 内容与仓库不同 —— 留着（不是我们装的那份）"
                elif [ "$DRY_RUN" = 1 ]; then
                    say "[$side] 会删 $dest"
                    removed=$((removed + 1))
                else
                    rm -rf "$dest"; say "[$side] 已删 $name"
                    removed=$((removed + 1))
                fi
            fi
            continue
        fi

        if [ -e "$dest" ] && [ "$FORCE" != 1 ]; then
            # 已经在了：如果是我们自己装的（内容一致），静默跳过；不一致就提醒
            if diff -rq "$src" "$dest" >/dev/null 2>&1; then
                skipped=$((skipped + 1))
            else
                say "[$side] ⚠️  $name 已存在且内容不同 —— 用 --force 覆盖"
                skipped=$((skipped + 1))
            fi
            continue
        fi

        # ⚠️ 备份不能放在 skills 目录里：Claude Code / Codex 会把带 SKILL.md
        #    的子目录都当成 skill 扫进去，于是 *.bak-* 会出现在技能列表里。
        backup_dir="$(dirname "$dest_root")/skill-backups"
        if [ "$DRY_RUN" = 1 ]; then
            if [ -e "$dest" ]; then
                say "[$side] 会先备份 $dest → $backup_dir/$name.bak-$BACKUP_TS，再装 $name"
            else
                say "[$side] 会装 $name → $dest"
            fi
        else
            mkdir -p "$dest_root"
            if [ -e "$dest" ]; then
                mkdir -p "$backup_dir"
                cp -a "$dest" "$backup_dir/$name.bak-$BACKUP_TS"
                say "[$side] 已备份 $name → $backup_dir/$name.bak-$BACKUP_TS"
                rm -rf "$dest"
            fi
            cp -r "$src" "$dest"
            say "[$side] ✅ 装了 $name"
        fi
        installed=$((installed + 1))
    done
done

# ── 全局：一装就知道自己是谁 ────────────────────────────────
# ⭐ 这是这个项目的重点 ——「安排好，装一次，两边就知道该干什么不该干什么」。
#    写进两边的【全局记忆】：
#      Claude Code → ~/.claude/CLAUDE.md
#      Codex       → ~/.codex/AGENTS.md
#        （Codex 二进制原话：core/src/agents_md.rs 的
#         "Failed to read global AGENTS.md instructions from ..." ⇒ 它确实读全局那份）
#
# ⚠️ 这两个文件【用户自己很可能已经有内容了】（本机 ~/.claude/CLAUDE.md 就有 18 行铁律）。
#    所以只用一对标记夹一段写进去，标记之外一个字都不碰；改前先备份。

put_global() {   # put_global <仓库里的模板> <目标文件> <说明>
    local src="$REPO_DIR/$1" dest="$2" what="$3"
    [ -f "$src" ] || { say "⚠️  仓库里没有 $src"; return; }

    # 标记不成对时拒绝任何修改（preflight 已检查；这里再兜一层）。
    check_global_marker_pair "$dest" "$what" || return 1

    if [ "$UNINSTALL" = 1 ]; then
        [ -e "$dest" ] || return
        grep -qF "$AF_BEGIN" "$dest" 2>/dev/null || { say "⏭  $what：没有我们那段，没动"; return; }
        if [ "$DRY_RUN" = 1 ]; then say "会从 $what 里删掉 agent-foreman 那段"; return; fi
        python3 - "$dest" "$AF_BEGIN" "$AF_END" <<'PY'
import os, sys, tempfile
p, begin, end_marker = sys.argv[1:4]
text = open(p, encoding="utf-8").read()
lines = text.split("\n")
starts = [i for i, ln in enumerate(lines) if ln.startswith(begin)]
ends = [i for i, ln in enumerate(lines) if ln.strip() == end_marker]
if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
    sys.stderr.write("install.sh: agent-foreman 标记不成对，拒绝修改。\n")
    sys.exit(3)
start, end = starts[0], ends[0]
out = lines[:start] + lines[end + 1:]
new_text = "\n".join(out)
if text.endswith("\n") and not new_text.endswith("\n"):
    new_text += "\n"
real = os.path.realpath(p)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(real) or ".", prefix=".agent-foreman-", text=True)
with os.fdopen(fd, "w", encoding="utf-8") as f:
    f.write(new_text)
if os.path.exists(real):
    os.chmod(tmp, os.stat(real).st_mode & 0o777)
os.replace(tmp, real)
PY
        say "✅ $what：删掉了 agent-foreman 那段（别的一句话没动）"
        return
    fi

    if [ "$DRY_RUN" = 1 ]; then
        say "会写进 $what：agent-foreman 角色说明（夹在标记之间，别的不动）"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    [ -e "$dest" ] && cp "$dest" "$dest.bak-$BACKUP_TS"
    python3 - "$src" "$dest" "$AF_BEGIN" "$AF_END" <<'PY'
import os, sys, tempfile
src, dest, begin, end_marker = sys.argv[1:5]
block = open(src, encoding="utf-8").read().rstrip("\n").split("\n")
try:
    old = open(dest, encoding="utf-8").read()
except FileNotFoundError:
    old = ""
lines = old.split("\n") if old else []
starts = [i for i, ln in enumerate(lines) if ln.startswith(begin)]
ends = [i for i, ln in enumerate(lines) if ln.strip() == end_marker]
if starts or ends:
    if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
        sys.stderr.write("install.sh: agent-foreman 标记不成对，拒绝修改。\n")
        sys.exit(3)
    new = lines[:starts[0]] + block + lines[ends[0] + 1:]
else:
    new = lines + ([""] if lines and lines[-1].strip() else []) + block
new_text = "\n".join(new)
if not new_text.endswith("\n"):
    new_text += "\n"
real = os.path.realpath(dest)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(real) or ".", prefix=".agent-foreman-", text=True)
with os.fdopen(fd, "w", encoding="utf-8") as f:
    f.write(new_text)
if os.path.exists(real):
    os.chmod(tmp, os.stat(real).st_mode & 0o777)
os.replace(tmp, real)
PY
    say "✅ $what：写入了 agent-foreman 角色说明"
}

head_ "全局角色说明（两边的全局记忆）"
put_global "templates/global-claude.md" "$HOME/.claude/CLAUDE.md"                     "Claude Code 全局记忆"
put_global "templates/global-codex.md"  "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"       "Codex 全局记忆"

# ── 全局：叫醒领导的那条命令 ────────────────────────────────
# ⭐ 也装成【全局】的 —— 它从 $PWD 往上找 .foreman/，所以放哪儿都行。
#    这样【新项目零配置】：不装 skill、不装脚本、什么都不用做。
BIN_DIR="${FOREMAN_BIN_DIR:-$HOME/.local/bin}"
head_ "全局命令（$BIN_DIR）"
if [ "$UNINSTALL" = 1 ]; then
    if [ ! -e "$BIN_DIR/notify-lead" ]; then
        say "⏭  $BIN_DIR/notify-lead 本来就没有"
    elif ! cmp -s "$REPO_DIR/scripts/notify-lead.sh" "$BIN_DIR/notify-lead"; then
        say "⏭  $BIN_DIR/notify-lead 内容与仓库不同 —— 留着（不是我们装的那份）"
    elif [ "$DRY_RUN" = 1 ]; then
        say "会删 $BIN_DIR/notify-lead"
    else
        rm -f "$BIN_DIR/notify-lead"; say "✅ 删了 notify-lead"
    fi
else
    if [ ! -e "$BIN_DIR/notify-lead" ]; then
        if [ "$DRY_RUN" = 1 ]; then
            say "会装 notify-lead → $BIN_DIR/notify-lead"
        else
            mkdir -p "$BIN_DIR"
            cp "$REPO_DIR/scripts/notify-lead.sh" "$BIN_DIR/notify-lead"
            chmod +x "$BIN_DIR/notify-lead"
            say "✅ notify-lead（在项目里任意位置跑都行）"
        fi
    elif cmp -s "$REPO_DIR/scripts/notify-lead.sh" "$BIN_DIR/notify-lead"; then
        if [ "$DRY_RUN" = 1 ]; then
            say "notify-lead 已是最新 → $BIN_DIR/notify-lead"
        else
            chmod +x "$BIN_DIR/notify-lead"
            say "✅ notify-lead 已是最新"
        fi
    elif [ "$FORCE" != 1 ]; then
        say "⚠️  $BIN_DIR/notify-lead 内容与仓库不同 —— 留着；用 --force 覆盖（会先备份）"
    elif [ "$DRY_RUN" = 1 ]; then
        say "会先备份 $BIN_DIR/notify-lead → $BIN_DIR/notify-lead.bak-$BACKUP_TS.*，再装"
    else
        mkdir -p "$BIN_DIR"
        # mktemp 保证同一秒内重复 --force 也不会覆盖已有备份。
        backup="$(mktemp "$BIN_DIR/notify-lead.bak-$BACKUP_TS.XXXXXX")"
        cp -a "$BIN_DIR/notify-lead" "$backup"
        cp "$REPO_DIR/scripts/notify-lead.sh" "$BIN_DIR/notify-lead"
        chmod +x "$BIN_DIR/notify-lead"
        say "⚠️  $BIN_DIR/notify-lead 已备份 → $backup，并装入仓库版本"
    fi
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) say "⚠️  $BIN_DIR 不在 PATH 里 —— 把它加进去才能直接敲 notify-lead" ;;
    esac
fi

# ── 项目级：把协作要用的文件放进那个项目 ────────────────────
# ⚠️ 安全铁律：**绝不覆盖/删除不是我们放的文件。**
#    项目里很可能本来就有 AGENTS.md / CLAUDE.md，那是人家自己的东西。
#    ⇒ 内容对不上就拒绝，只在卸载时删【与本仓库逐字节相同】的那些。
if [ -n "$PROJECT" ]; then
    [ -d "$PROJECT" ] || { printf 'install.sh: 项目目录不存在：%s\n' "$PROJECT" >&2; exit 2; }
    PROJ="$(cd "$PROJECT" && pwd)"
    head_ "项目：$PROJ"
    proj_done=0   # 项目里实际放了/删了几项（汇总要用）

    same_as_ours() { [ -f "$1" ] && [ -f "$2" ] && cmp -s "$1" "$2"; }

    put() {   # put <仓库里的源> <项目里的目标> <说明>
        local s="$REPO_DIR/$1" d="$PROJ/$2" what="$3"
        if [ -e "$d" ] && ! same_as_ours "$s" "$d"; then
            if [ "$FORCE" = 1 ]; then
                if [ "$DRY_RUN" = 1 ]; then
                    say "⚠️  $what 已存在且内容不同 —— 会先备份 $d → $d.bak-$BACKUP_TS，再覆盖"
                else
                    cp "$d" "$d.bak-$BACKUP_TS"
                    say "⚠️  $what 已存在且内容不同 —— 已备份 $d.bak-$BACKUP_TS，再覆盖"
                fi
            else
                say "⏭  $what 已存在且内容不同 —— 没动它。"
                case "$2" in
                    AGENTS.md)
                        say "    要合进去，请把 templates/AGENTS.md 里的角色说明手工合并到现有 AGENTS.md；"
                        say "    不要加 @AGENTS.md（那是自引用）。"
                        ;;
                    *)
                        say "    要合进去，自己把这一行加到 $2 末尾：  @AGENTS.md"
                        ;;
                esac
                return
            fi
        fi
        if [ "$DRY_RUN" = 1 ]; then say "会放 $what → $d"
        else mkdir -p "$(dirname "$d")"; cp "$s" "$d"; say "✅ $what"; fi
        proj_done=$((proj_done + 1))
    }

    if [ "$UNINSTALL" = 1 ]; then
        for rel in "AGENTS.md" "CLAUDE.md"; do
            d="$PROJ/$rel"
            if same_as_ours "$REPO_DIR/$(case $rel in
                    .foreman/*) echo "scripts/notify-lead.sh" ;;
                    AGENTS.md)  echo "templates/AGENTS.md" ;;
                    CLAUDE.md)  echo "templates/CLAUDE.md" ;;
                esac)" "$d"; then
                [ "$DRY_RUN" = 1 ] && say "会删 $rel" || { rm -f "$d"; say "已删 $rel"; }
                proj_done=$((proj_done + 1))
            elif [ -e "$d" ]; then
                say "⏭  $rel 不是我们放的（内容不同）—— 留着"
            fi
        done
    else
        [ -d "$PROJ/.foreman" ] || { [ "$DRY_RUN" = 1 ] || mkdir -p "$PROJ/.foreman"; }
        # ⚠️ notify-lead 已经【全局】装了（见上面），这里不再往项目里放脚本。
        #    --project 现在只干一件事：让项目【自带说明】——
        #    别人 clone 下来、又没装全局时，看 AGENTS.md 也知道该怎么配合。
        put "templates/AGENTS.md"    "AGENTS.md"                "AGENTS.md（Codex 开场读）"
        put "templates/CLAUDE.md"    "CLAUDE.md"                "CLAUDE.md（Claude 开场读 → AGENTS.md）"
    fi
fi

head_ "完成"
if [ "$UNINSTALL" = 1 ]; then
    say "卸载 skill $removed 项${PROJECT:+，项目文件 $proj_done 项}"
else
    say "新装 skill $installed 项，跳过 $skipped 项${PROJECT:+；项目文件 $proj_done 项}"
fi

if [ "$UNINSTALL" != 1 ] && [ "$DRY_RUN" != 1 ]; then
    cat <<'EOF'

下一步：
  1. Codex 侧：重启 Codex（或新开会话）让它扫到新 skill
  2. Claude Code 侧：新会话即可，skill 会出现在可用列表里
  3. 验证：在 Codex 界面左侧的「协作」面板里应该能看到 tech-lead / cross-review

⚠️ 如果 Codex 界面里显示不全，检查 SKILL.md 的 frontmatter 里有没有
   metadata.short-description —— 缺了它 Codex 会报 missing short_description。
EOF
fi
