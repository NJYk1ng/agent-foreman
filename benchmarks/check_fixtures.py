#!/usr/bin/env python3
"""Validate the benchmark task fixtures.

Layout per task:
  metadata.json  required fields
  task.md        participant-visible prompt
  workspace/     fixed starting snapshot
  solution/      files overlaid to make the grader pass
  grader/        grader + hidden tests, outside the visible workspace
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TASKS = ROOT / "tasks"
REQUIRED = (
    "id",
    "title",
    "task_file",
    "workspace",
    "solution",
    "grader",
    "hidden_tests",
    "snapshot_sha256",
)


def snapshot_hash(path):
    h = hashlib.sha256()
    for p in sorted(path.rglob("*")):
        if p.is_dir() or "__pycache__" in p.parts or p.suffix == ".pyc":
            continue
        rel = p.relative_to(path).as_posix()
        h.update(rel.encode("utf-8"))
        h.update(b"\0")
        h.update(p.read_bytes())
        h.update(b"\0")
    return h.hexdigest()


def is_inside(child, parent):
    child = child.resolve()
    parent = parent.resolve()
    return child == parent or parent in child.parents


def run_grader(task_dir, metadata, workspace):
    grader = task_dir / metadata["grader"]
    if grader.suffix == ".py":
        cmd = [sys.executable, str(grader), str(workspace)]
    elif grader.suffix == ".sh":
        cmd = ["bash", str(grader), str(workspace)]
    else:
        return None, f"unsupported grader type: {grader.suffix}"
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    try:
        proc = subprocess.run(
            cmd,
            cwd=task_dir,
            env=env,
            capture_output=True,
            text=True,
            timeout=20,
        )
    except subprocess.TimeoutExpired:
        return None, "grader timed out after 20s"
    return proc, None


def check_task(task_dir):
    name = task_dir.name
    errors = []
    try:
        metadata = json.loads((task_dir / "metadata.json").read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"❌ {name}: missing metadata.json", file=sys.stderr)
        return False
    except json.JSONDecodeError as e:
        print(f"❌ {name}: metadata.json is not valid JSON: {e}", file=sys.stderr)
        return False

    for field in REQUIRED:
        if field not in metadata:
            errors.append(f"missing metadata field '{field}'")
    if errors:
        for e in errors:
            print(f"❌ {name}: {e}", file=sys.stderr)
        return False

    task_file = task_dir / metadata["task_file"]
    workspace = task_dir / metadata["workspace"]
    solution = task_dir / metadata["solution"]
    grader = task_dir / metadata["grader"]

    for label, path in (
        ("task_file", task_file),
        ("workspace", workspace),
        ("solution", solution),
        ("grader", grader),
    ):
        if not path.exists():
            errors.append(f"{label} does not exist: {path.relative_to(task_dir)}")
    if errors:
        for e in errors:
            print(f"❌ {name}: {e}", file=sys.stderr)
        return False

    if not task_file.is_file() or task_file.stat().st_size == 0:
        errors.append("task_file is empty")
    if not workspace.is_dir() or not any(p.is_file() for p in workspace.rglob("*")):
        errors.append("workspace is empty")
    if not solution.is_dir() or not any(p.is_file() for p in solution.rglob("*")):
        errors.append("solution is empty")
    if is_inside(task_file, workspace):
        errors.append("task_file is inside the agent-visible workspace")
    if is_inside(solution, workspace):
        errors.append("solution is inside the agent-visible workspace")
    if is_inside(grader, workspace):
        errors.append("grader is inside the agent-visible workspace")

    for hidden in metadata["hidden_tests"]:
        hp = task_dir / hidden
        if not hp.is_file():
            errors.append(f"hidden test missing: {hidden}")
        elif is_inside(hp, workspace):
            errors.append(f"hidden test is inside the workspace: {hidden}")
        elif not is_inside(hp, task_dir / "grader"):
            errors.append(f"hidden test is outside grader/: {hidden}")

    if errors:
        for e in errors:
            print(f"❌ {name}: {e}", file=sys.stderr)
        return False

    actual = snapshot_hash(workspace)
    if actual != metadata["snapshot_sha256"]:
        print(
            f"❌ {name}: snapshot hash mismatch "
            f"(expected {metadata['snapshot_sha256']}, got {actual})",
            file=sys.stderr,
        )
        return False
    print(f"✅ {name}: structure + snapshot")

    with tempfile.TemporaryDirectory() as tmp:
        start = Path(tmp) / "start"
        shutil.copytree(workspace, start)
        proc, error = run_grader(task_dir, metadata, start)
        if error:
            print(f"❌ {name}: {error}", file=sys.stderr)
            return False
        if proc.returncode == 0:
            print(f"❌ {name}: starting snapshot already passes the grader", file=sys.stderr)
            return False
        print(f"✅ {name}: starting snapshot fails as expected")

        solved = Path(tmp) / "solved"
        shutil.copytree(workspace, solved)
        shutil.copytree(solution, solved, dirs_exist_ok=True)
        proc, error = run_grader(task_dir, metadata, solved)
        if error:
            print(f"❌ {name}: {error}", file=sys.stderr)
            return False
        if proc.returncode != 0:
            detail = (proc.stdout + proc.stderr).strip()
            print(f"❌ {name}: solution does not pass the grader: {detail}", file=sys.stderr)
            return False
        print(f"✅ {name}: solution passes")
    return True


def main():
    if not TASKS.is_dir():
        print(f"❌ missing tasks directory: {TASKS}", file=sys.stderr)
        return 1
    task_dirs = sorted(p for p in TASKS.iterdir() if p.is_dir())
    if len(task_dirs) < 3:
        print(f"❌ need at least 3 task fixtures, found {len(task_dirs)}", file=sys.stderr)
        return 1

    seen = set()
    ok = True
    for task_dir in task_dirs:
        try:
            metadata = json.loads((task_dir / "metadata.json").read_text(encoding="utf-8"))
        except Exception:
            metadata = {}
        task_id = metadata.get("id", "")
        if task_id and task_id in seen:
            print(f"❌ {task_dir.name}: duplicate task id '{task_id}'", file=sys.stderr)
            ok = False
        if task_id:
            seen.add(task_id)
        if not check_task(task_dir):
            ok = False

    if not ok:
        print("fixtures: FAILED", file=sys.stderr)
        return 1
    print(f"fixtures: {len(task_dirs)} tasks OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
