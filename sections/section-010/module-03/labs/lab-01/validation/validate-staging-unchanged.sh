#!/usr/bin/env bash
# PASS when staging still runs 1 ready replica with the message staging, owned by
# the Flux Kustomization staging.
set -uo pipefail

D="kubectl -n staging get deployment podinfo"
$D >/dev/null 2>&1 || { echo "FAIL: no Deployment podinfo in the namespace staging."; exit 1; }
READY="$($D -o jsonpath='{.status.readyReplicas}')"
MSG="$($D -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}')"
OWNER="$($D -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}')"
[ "${READY:-0}" = "1" ] || { echo "FAIL: ${READY:-0} ready replicas in staging, expected 1."; exit 1; }
[ "$MSG" = "staging" ] || { echo "FAIL: PODINFO_UI_MESSAGE is '$MSG' in staging, expected staging."; exit 1; }
[ "$OWNER" = "staging" ] || { echo "FAIL: the Deployment in staging is owned by '$OWNER', expected staging."; exit 1; }
echo "PASS: staging runs its own configuration."
exit 0
