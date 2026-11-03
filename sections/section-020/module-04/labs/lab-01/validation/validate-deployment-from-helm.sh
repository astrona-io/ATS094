#!/usr/bin/env bash
# PASS when the Deployment podinfo in the namespace podinfo comes from a 6.x
# chart, runs 2 ready replicas, has the message, and is owned by the HelmRelease.
set -uo pipefail

D="kubectl -n podinfo get deployment podinfo"
if ! $D >/dev/null 2>&1; then
  echo "FAIL: no Deployment podinfo in the namespace podinfo."
  exit 1
fi
CHART="$($D -o jsonpath='{.metadata.labels.helm\.sh/chart}')"
READY="$($D -o jsonpath='{.status.readyReplicas}')"
MSG="$($D -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}')"
OWNER="$($D -o jsonpath='{.metadata.labels.helm\.toolkit\.fluxcd\.io/name}')"

case "$CHART" in
  podinfo-6.*) ;;
  *) echo "FAIL: the Deployment label helm.sh/chart is '$CHART', expected podinfo-6.*."; exit 1 ;;
esac
[ "${READY:-0}" = "2" ] || { echo "FAIL: ${READY:-0} ready replicas, expected 2."; exit 1; }
[ "$MSG" = "hello from helm" ] || { echo "FAIL: PODINFO_UI_MESSAGE is '$MSG', expected 'hello from helm'."; exit 1; }
[ "$OWNER" = "podinfo" ] || { echo "FAIL: the Deployment is not managed by the HelmRelease podinfo (label: '$OWNER')."; exit 1; }
echo "PASS: the Deployment comes from $CHART with 2 ready replicas and the right message."
exit 0
