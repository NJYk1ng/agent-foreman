#!/usr/bin/env bash
#
# foreman-check.sh — 检查当前计划的契约完整性、工人入口护栏和脚本语法。
#
# 用法：
#   ./scripts/foreman-check.sh                  # 检查仓库根
#   ./scripts/foreman-check.sh --root <目录>    # 检查指定目录（测试用）
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<'EOF'
foreman-check — 检查当前计划的契约完整性、工人入口护栏和脚本语法。

用法：
  ./scripts/foreman-check.sh                  # 检查仓库根
  ./scripts/foreman-check.sh --root <目录>    # 检查指定目录（测试用）
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --root)
            shift
            [ $# -gt 0 ] || { printf 'foreman-check: --root 后面要跟目录\n' >&2; exit 2; }
            ROOT="$(cd "$1" 2>/dev/null && pwd)" || {
                printf 'foreman-check: 目录不存在：%s\n' "$1" >&2; exit 2
            }
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'foreman-check: 未知参数 %s（试 --help）\n' "$1" >&2
            exit 2
            ;;
    esac
    shift
done

fail=0
err() { printf '❌ %s\n' "$*" >&2; fail=1; }
ok()  { printf '✅ %s\n' "$*"; }

PLAN="$ROOT/.foreman/PLAN.md"
if [ -s "$PLAN" ]; then
    ok "计划存在且非空：$PLAN"
elif [ -d "$ROOT/.foreman/archive" ] && [ -n "$(find "$ROOT/.foreman/archive" -type f -print -quit 2>/dev/null)" ]; then
    # 计划已完成并归档：没有活跃计划不是错误，CI 仍需能跑模板/脚本检查。
    ok "没有活跃计划（已归档）；跳过计划检查"
else
    err "缺少或空的计划：$PLAN"
fi

# 计划结构：每个任务必须有五个字段、至少一条 AC、编号唯一。
if [ -s "$PLAN" ]; then
    python3 - "$PLAN" <<'PY'
import re
import sys

path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines()
tasks = []
current = None

for line in lines:
    m = re.match(r"^###\s+(T\d+)\b(.*)$", line)
    if m:
        current = {"id": m.group(1), "lines": []}
        tasks.append(current)
    elif line.startswith("## ") and current is not None:
        current = None
    elif current is not None:
        current["lines"].append(line)

errors = []
seen = set()
for task in tasks:
    tid = task["id"]
    if tid in seen:
        errors.append(f"{tid}: 任务编号重复")
    seen.add(tid)
    body = "\n".join(task["lines"])
    for field in ("目标", "谁写", "依赖", "验收标准", "边界"):
        if f"**{field}**" not in body:
            errors.append(f"{tid}: 缺少字段「{field}」")
    # 验收标准的“值”是后面的 AC 行；其余四个字段要求冒号后有内容。
    for field in ("目标", "谁写", "依赖", "边界"):
        m = re.search(rf"\*\*{field}\*\*[：:]\s*(.*)", body)
        if m and not m.group(1).strip():
            errors.append(f"{tid}: 字段「{field}」的值为空")
    m = re.search(r"\*\*谁写\*\*：\s*(\S+)", body)
    if m and m.group(1) != "工人":
        errors.append(f"{tid}: 谁写不是「工人」")
    acs = re.findall(r"^\s*-\s+AC\d+\s+\[(命令|观察|现场)\]", body, re.M)
    if not acs:
        errors.append(f"{tid}: 没有 AC，或 AC 没有 [命令]/[观察]/[现场] 级别")
    for line in body.splitlines():
        if re.match(r"^\s*-\s+AC\d+", line) and not re.match(
            r"^\s*-\s+AC\d+\s+\[(命令|观察|现场)\]", line
        ):
            errors.append(f"{tid}: AC 级别不合法：{line.strip()}")

if not tasks:
    errors.append("没有找到任何 ### T<n> 任务")

for error in errors:
    print(f"❌ 计划：{error}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
    [ $? -eq 0 ] || fail=1
fi

# 工人入口必须有无计划停工护栏。
for file in templates/AGENTS.md templates/global-claude.md skills/execute-plan/SKILL.md; do
    if grep -q '没有 .foreman/PLAN.md.*停止' "$ROOT/$file" 2>/dev/null; then
        ok "停工护栏：$file"
    else
        err "缺少无计划停工护栏：$file"
    fi
done

# 脚本语法。
for file in install.sh scripts/notify-lead.sh scripts/foreman-check.sh; do
    if bash -n "$ROOT/$file" 2>/dev/null; then
        ok "语法：$file"
    else
        err "语法错误：$file"
        bash -n "$ROOT/$file" 2>&1 | sed 's/^/    /' >&2
    fi
done

if python3 - "$ROOT/scripts/check-links.py" <<'PY'
import ast
import sys

try:
    ast.parse(open(sys.argv[1], encoding="utf-8").read())
except FileNotFoundError:
    sys.exit(1)
except SyntaxError as e:
    print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
then
    ok "语法：scripts/check-links.py"
else
    err "语法错误：scripts/check-links.py"
fi

if [ "$fail" -ne 0 ]; then
    printf 'foreman-check: 失败\n' >&2
    exit 1
fi
printf 'foreman-check: 通过\n'
