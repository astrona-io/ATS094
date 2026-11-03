#!/usr/bin/env bash
# PASS when the Widget main exists in infra, applied by infrastructure-configs,
# and the Deployment podinfo in apps runs 2 ready replicas, applied by apps.
set -uo pipefail

W="kubectl -n infra get widget main"
$W >/dev/null 2>&1 || { echo "FAIL: no Widget main in the namespace infra."; exit 1; }
WO="$($W -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}')"
[ "$WO" = "infrastructure-configs" ] || { echo "FAIL: the Widget is owned by '$WO', expected infrastructure-configs."; exit 1; }

D="kubectl -n apps get deployment podinfo"
$D >/dev/null 2>&1 || { echo "FAIL: no Deployment podinfo in the namespace apps."; exit 1; }
READY="$($D -o jsonpath='{.status.readyReplicas}')"
DO="$($D -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}')"
[ "${READY:-0}" = "2" ] || { echo "FAIL: ${READY:-0} ready replicas in apps, expected 2."; exit 1; }
[ "$DO" = "apps" ] || { echo "FAIL: the Deployment is owned by '$DO', expected the Flux Kustomization apps."; exit 1; }
echo "PASS: the Widget exists and podinfo runs the cluster overlay."
exit 0
