#!/usr/bin/env bash
# PASS when the podinfo Deployment was applied by the Flux Kustomization
# podinfo (it carries Flux's ownership labels) and runs the two ready replicas
# that Git asks for. Rejects a podinfo applied by hand with kubectl.
set -uo pipefail

NS="podinfo"

owner="$(kubectl -n "$NS" get deployment podinfo \
  -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"
if [ "$owner" != "podinfo" ]; then
  echo "FAIL: deployment podinfo in $NS is missing or was not applied by the Flux Kustomization podinfo."
  exit 1
fi

ready=""
for _ in $(seq 1 12); do
  ready="$(kubectl -n "$NS" get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "$ready" = "2" ] && break
  sleep 5
done
if [ "$ready" != "2" ]; then
  echo "FAIL: deployment podinfo has '${ready:-0}' ready replicas, expected 2 as in Git."
  exit 1
fi

echo "PASS: podinfo runs 2 ready replicas, applied by Flux."
exit 0
