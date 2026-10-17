#!/usr/bin/env bash
set -euo pipefail

# BUG (intentional): only prints the first argument.
printf '%s\n' "${1:-0}"
