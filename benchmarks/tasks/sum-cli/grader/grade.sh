#!/usr/bin/env bash
set -euo pipefail

exec bash "$(dirname "$0")/test_sum.sh" "$1"
