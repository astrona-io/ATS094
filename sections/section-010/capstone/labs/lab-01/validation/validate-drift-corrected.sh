#!/usr/bin/env bash
# PASS when Flux puts a manual change back: the grader scales podinfo to 1,
# asks kustomize-controller to reconcile, and expects 3 replicas again.
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo scale deployment podinfo --replicas=1 >/dev/null 2>&1 || {
  echo "FAIL: could not scale the Deployment podinfo."
  exit 1
}
flux reconcile kustomization podinfo --timeout=3m >/dev/null 2>&1

SPEC=""
for _ in $(seq 1 30); do
  SPEC="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [ "$SPEC" = "3" ] && break
  sleep 2
done
if [ "$SPEC" != "3" ]; then
  echo "FAIL: after a manual scale to 1 and a reconcile, podinfo still wants ${SPEC:-?} replicas. Flux did not correct the drift."
  exit 1
fi

echo "PASS: Flux corrected a manual scale back to the 3 replicas in Git."
exit 0
