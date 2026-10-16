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

installed=0
skipped=0
removed=0

head_ "agent-foreman 安装器"
say "仓库    : $REPO_DIR"
say "Claude 侧: $CLAUDE_DIR"
say "Codex 侧 : $CODEX_DIR"
[ "$DRY_RUN" = 1 ]   && say "模式    : dry-run（不会动任何文件）"
[ "$UNINSTALL" = 1 ] && say "模式    : 卸载"

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
                if [ "$DRY_RUN" = 1 ]; then
                    say "[$side] 会删 $dest"
                else
                    rm -rf "$dest"; say "[$side] 已删 $name"
                fi
                removed=$((removed + 1))
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

        if [ "$DRY_RUN" = 1 ]; then
            say "[$side] 会装 $name → $dest"
        else
            mkdir -p "$dest_root"
            rm -rf "$dest"
            cp -r "$src" "$dest"
            say "[$side] ✅ 装了 $name"
        fi
        installed=$((installed + 1))
    done
done

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
                say "⚠️  $what 已存在且内容不同 —— --force，覆盖（原文件没备份，自己确认过）"
            else
                say "⏭  $what 已存在且内容不同 —— 没动它。"
                say "    要合进去，自己把这一行加到 $2 末尾：  @AGENTS.md"
                return
            fi
        fi
        if [ "$DRY_RUN" = 1 ]; then say "会放 $what → $d"
        else mkdir -p "$(dirname "$d")"; cp "$s" "$d"; say "✅ $what"; fi
        proj_done=$((proj_done + 1))
    }

    if [ "$UNINSTALL" = 1 ]; then
        for rel in ".foreman/notify-lead.sh" "AGENTS.md" "CLAUDE.md"; do
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
        put "scripts/notify-lead.sh" ".foreman/notify-lead.sh" "notify-lead.sh（工人干完通知领导）"
        put "templates/AGENTS.md"    "AGENTS.md"                "AGENTS.md（Codex 开场读）"
        put "templates/CLAUDE.md"    "CLAUDE.md"                "CLAUDE.md（Claude 开场读 → AGENTS.md）"
        [ "$DRY_RUN" = 1 ] || chmod +x "$PROJ/.foreman/notify-lead.sh" 2>/dev/null || true
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
