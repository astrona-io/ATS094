#!/usr/bin/env bash
# PASS when the Deployment podinfo in the namespace podinfo was applied by Flux,
# runs 2 ready replicas, and has the message stored in the ConfigMap
# cluster-vars.
set -uo pipefail

WANT="$(kubectl -n flux-system get configmap cluster-vars -o jsonpath='{.data.ui_message}' 2>/dev/null)"
if [ -z "$WANT" ]; then
  echo "FAIL: the ConfigMap cluster-vars with the key ui_message must stay in flux-system."
  exit 1
fi
GOT="$(kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}' 2>/dev/null)"
READY="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
OWNER="$(kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"

if [ "$GOT" != "$WANT" ]; then
  echo "FAIL: PODINFO_UI_MESSAGE is '$GOT', expected '$WANT'."
  exit 1
fi
if [ "${READY:-0}" != "2" ]; then
  echo "FAIL: deployment podinfo has ${READY:-0} ready replicas, expected 2."
  exit 1
fi
if [ "$OWNER" != "podinfo" ]; then
  echo "FAIL: the Deployment was not applied by the Flux Kustomization podinfo (label: '$OWNER')."
  exit 1
fi
echo "PASS: podinfo runs with the message '$GOT' from the ConfigMap."
exit 0
