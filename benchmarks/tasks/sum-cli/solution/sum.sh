#!/usr/bin/env bash
set -euo pipefail

total=0
for arg in "$@"; do
    if [[ ! "$arg" =~ ^-?[0-9]+$ ]]; then
        printf 'error: non-integer argument: %s\n' "$arg" >&2
        exit 2
    fi
    total=$(( total + arg ))
done
printf '%s\n' "$total"
