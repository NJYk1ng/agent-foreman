#!/usr/bin/env python3
"""Run the hidden wordcount tests against a submitted workspace."""

import os
import subprocess
import sys


def main():
    workspace = os.path.abspath(sys.argv[1])
    here = os.path.dirname(os.path.abspath(__file__))
    env = os.environ.copy()
    env["PYTHONPATH"] = workspace + os.pathsep + env.get("PYTHONPATH", "")
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return subprocess.call(
        [sys.executable, "-m", "unittest", "test_wordcount"],
        cwd=here,
        env=env,
    )


if __name__ == "__main__":
    sys.exit(main())
