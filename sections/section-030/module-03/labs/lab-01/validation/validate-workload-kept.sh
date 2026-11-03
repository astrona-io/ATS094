#!/usr/bin/env bash
# PASS when podinfo still runs 2 ready replicas and is the same Deployment
# (same UID) that ran when the lab started.
set -uo pipefail

D="kubectl -n podinfo get deployment podinfo"
$D >/dev/null 2>&1 || { echo "FAIL: the Deployment podinfo is gone."; exit 1; }
READY="$($D -o jsonpath='{.status.readyReplicas}')"
NOW="$($D -o jsonpath='{.metadata.uid}')"
WAS="$(kubectl -n default get configmap lab-baseline -o jsonpath='{.data.deployment-uid}' 2>/dev/null)"
[ -n "$WAS" ] || { echo "FAIL: the ConfigMap lab-baseline is missing."; exit 1; }
[ "$NOW" = "$WAS" ] || { echo "FAIL: the Deployment was deleted and created again."; exit 1; }
[ "${READY:-0}" = "2" ] || { echo "FAIL: ${READY:-0} ready replicas, expected 2."; exit 1; }
echo "PASS: podinfo kept running through the uninstall."
exit 0
