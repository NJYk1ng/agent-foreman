#!/usr/bin/env bash
set -uo pipefail

ws="$1"
fail=0

run_case() {
    local desc="$1"; shift
    local expected_out="$1"; shift
    local expected_rc="$1"; shift
    local out rc
    out="$(bash "$ws/sum.sh" "$@" 2>&1)"; rc=$?
    if [ "$out" != "$expected_out" ] || [ "$rc" -ne "$expected_rc" ]; then
        printf 'FAIL %s: out=[%s] rc=%s expected out=[%s] rc=%s\n' \
            "$desc" "$out" "$rc" "$expected_out" "$expected_rc" >&2
        fail=1
    fi
}

run_case "no args" "0" 0
run_case "positive" "6" 0 1 2 3
run_case "negative" "-3" 0 -5 2
run_case "all negative" "-6" 0 -1 -2 -3
run_case "non-integer" "error: non-integer argument: x" 2 1 x

exit "$fail"
