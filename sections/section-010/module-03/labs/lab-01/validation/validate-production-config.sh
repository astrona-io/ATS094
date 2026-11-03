#!/usr/bin/env bash
# PASS when the Deployment podinfo in the namespace production runs 2 ready
# replicas with the message production, applied by the Flux Kustomization
# production.
set -uo pipefail

D="kubectl -n production get deployment podinfo"
$D >/dev/null 2>&1 || { echo "FAIL: no Deployment podinfo in the namespace production."; exit 1; }
READY="$($D -o jsonpath='{.status.readyReplicas}')"
MSG="$($D -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}')"
OWNER="$($D -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}')"
[ "${READY:-0}" = "2" ] || { echo "FAIL: ${READY:-0} ready replicas in production, expected 2."; exit 1; }
[ "$MSG" = "production" ] || { echo "FAIL: PODINFO_UI_MESSAGE is '$MSG', expected production."; exit 1; }
[ "$OWNER" = "production" ] || { echo "FAIL: the Deployment is owned by '$OWNER', expected the Flux Kustomization production."; exit 1; }
echo "PASS: production runs 2 replicas with the message production."
exit 0
