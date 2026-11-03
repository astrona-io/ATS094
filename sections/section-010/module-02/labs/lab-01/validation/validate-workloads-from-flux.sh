#!/usr/bin/env bash
# PASS when both Deployments run their replicas and each carries the label of
# the Flux Kustomization that applied it (infra and apps).
set -uo pipefail

FAILED=0
check() {
  # check NAMESPACE DEPLOYMENT REPLICAS KUSTOMIZATION
  local ns="$1" name="$2" want="$3" ks="$4" ready owner
  ready="$(kubectl -n "$ns" get deployment "$name" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  owner="$(kubectl -n "$ns" get deployment "$name" \
    -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"
  if [ "${ready:-0}" != "$want" ]; then
    echo "FAIL: deployment $name in $ns has ${ready:-0} ready replicas, expected $want."
    FAILED=1
  fi
  if [ "$owner" != "$ks" ]; then
    echo "FAIL: deployment $name in $ns was not applied by the Flux Kustomization $ks (label: '${owner}')."
    FAILED=1
  fi
}
check platform cache 1 infra
check podinfo podinfo 2 apps
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: both Deployments run and Flux applied them."
exit 0
