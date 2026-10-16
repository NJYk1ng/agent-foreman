#!/usr/bin/env bash
#
# 把 agent-foreman 的 skill 装到各自该去的那一侧。
#
# 为什么需要这个：两个 harness 的 skill 格式是同一套（SKILL.md + name/description），
# 但【不自动同步】—— 实测：只放 `~/.claude/skills/` 的 skill，Codex 看不到，反之亦然。
#
# 用法：
#   ./install.sh              装（已存在的会跳过，除非 --force）
#   ./install.sh --dry-run    只说要做什么，不动文件
#   ./install.sh --uninstall  卸掉本仓库装的那些
#   ./install.sh --force      覆盖已存在的
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

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --force)     FORCE=1 ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help)   sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'install.sh: 未知参数 %s（试 --help）\n' "$arg" >&2; exit 2 ;;
    esac
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

head_ "完成"
if [ "$UNINSTALL" = 1 ]; then
    say "卸载 $removed 项"
else
    say "新装 $installed 项，跳过 $skipped 项"
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
