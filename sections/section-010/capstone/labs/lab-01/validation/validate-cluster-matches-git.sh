#!/usr/bin/env bash
# PASS when the cluster matches Git: podinfo runs 3 ready replicas, and the
# debug pod is gone from the cluster and from the Flux inventory.
set -uo pipefail

SPEC=""; READY=""
for _ in $(seq 1 40); do
  SPEC="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  READY="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "$SPEC" = "3" ] && [ "$READY" = "3" ] && break
  sleep 3
done
if [ "$SPEC" != "3" ] || [ "$READY" != "3" ]; then
  echo "FAIL: podinfo wants ${SPEC:-?} replicas with ${READY:-0} ready; Git asks for 3."
  exit 1
fi

if kubectl -n podinfo get pod debug >/dev/null 2>&1; then
  echo "FAIL: the pod debug still runs in the namespace podinfo."
  exit 1
fi
if kubectl -n flux-system get kustomization podinfo \
     -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' | grep -q '^podinfo_debug__Pod$'; then
  echo "FAIL: the pod debug is still in the inventory of the Flux Kustomization podinfo."
  exit 1
fi

echo "PASS: the cluster matches Git: 3 ready replicas and no debug pod."
exit 0
