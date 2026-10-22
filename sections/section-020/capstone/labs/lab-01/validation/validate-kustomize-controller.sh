#!/usr/bin/env bash
# PASS when kustomize-controller has at least one ready replica.
set -uo pipefail

ready="$(kubectl -n flux-system get deployment kustomize-controller \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
  echo "FAIL: kustomize-controller has no ready replica."
  exit 1
fi

echo "PASS: kustomize-controller has $ready ready replica(s)."
exit 0
