#!/usr/bin/env bash
# PASS when the namespace flux-system and the ConfigMap team-notes still exist.
set -uo pipefail

kubectl get namespace flux-system >/dev/null 2>&1 || { echo "FAIL: the namespace flux-system was deleted."; exit 1; }
NOTE="$(kubectl -n flux-system get configmap team-notes -o jsonpath='{.data.note}' 2>/dev/null)"
[ -n "$NOTE" ] || { echo "FAIL: the ConfigMap team-notes is missing or empty."; exit 1; }
echo "PASS: flux-system and team-notes remain."
exit 0
