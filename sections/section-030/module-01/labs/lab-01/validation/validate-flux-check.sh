#!/usr/bin/env bash
# PASS when `flux check` reports every Flux component installed and healthy.
set -uo pipefail

OUT="$(flux check 2>&1)"
RC=$?
if [ $RC -ne 0 ]; then
  echo "FAIL: flux check did not pass:"
  printf '%s\n' "$OUT"
  exit 1
fi

echo "PASS: flux check reports the Flux components installed and healthy."
exit 0
