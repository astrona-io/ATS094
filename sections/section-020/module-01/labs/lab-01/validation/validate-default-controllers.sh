#!/usr/bin/env bash
# PASS when the four default Flux controllers are still Available and
# `flux check` passes. Rejects an install with --components that dropped a
# default controller.
set -uo pipefail

NS="flux-system"
FAILED=0

for controller in source-controller kustomize-controller helm-controller notification-controller; do
  available="$(kubectl -n "$NS" get deployment "$controller" \
    -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)"
  if [ "$available" != "True" ]; then
    echo "FAIL: default controller $controller is not Available in $NS."
    FAILED=1
  fi
done

if ! OUT="$(flux check 2>&1)"; then
  echo "FAIL: flux check does not pass:"
  printf '%s\n' "$OUT"
  FAILED=1
fi

[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: the four default controllers are Available and flux check passes."
exit 0
