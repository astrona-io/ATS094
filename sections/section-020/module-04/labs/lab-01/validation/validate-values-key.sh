#!/usr/bin/env bash
# PASS when the values of the HelmRelease use replicaCount: 2, no longer contain
# the key replicas, and still carry the message.
set -uo pipefail

HR="kubectl -n flux-system get helmrelease podinfo"
COUNT="$($HR -o jsonpath='{.spec.values.replicaCount}' 2>/dev/null)"
WRONG="$($HR -o jsonpath='{.spec.values.replicas}' 2>/dev/null)"
MSG="$($HR -o jsonpath='{.spec.values.ui.message}' 2>/dev/null)"

[ "$COUNT" = "2" ] || { echo "FAIL: spec.values.replicaCount is '$COUNT', expected 2."; exit 1; }
[ -z "$WRONG" ] || { echo "FAIL: spec.values.replicas is still set; the chart does not read it."; exit 1; }
[ "$MSG" = "hello from helm" ] || { echo "FAIL: spec.values.ui.message is '$MSG', expected 'hello from helm'."; exit 1; }
echo "PASS: the values use replicaCount and keep the message."
exit 0
