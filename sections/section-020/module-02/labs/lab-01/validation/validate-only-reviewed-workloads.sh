#!/usr/bin/env bash
# PASS when the Deployment podinfo was applied by Flux and runs 2 ready
# replicas, and the Deployment unreviewed does not exist.
set -uo pipefail

READY="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
OWNER="$(kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"

if [ "${READY:-0}" != "2" ]; then
  echo "FAIL: deployment podinfo has ${READY:-0} ready replicas, expected 2."
  exit 1
fi
if [ "$OWNER" != "podinfo" ]; then
  echo "FAIL: deployment podinfo was not applied by the Flux Kustomization podinfo (label: '$OWNER')."
  exit 1
fi
if kubectl -n podinfo get deployment unreviewed >/dev/null 2>&1; then
  echo "FAIL: the Deployment unreviewed exists. Only the state of the tag release-1 may run."
  exit 1
fi
echo "PASS: podinfo runs from Flux and unreviewed does not exist."
exit 0
