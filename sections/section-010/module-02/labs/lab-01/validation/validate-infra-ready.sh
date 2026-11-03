#!/usr/bin/env bash
# PASS when the Flux Kustomization infra applies ./infrastructure, keeps a
# health check on the Deployment cache in the namespace platform, prunes, is
# not suspended and is Ready.
set -uo pipefail

KS="kubectl -n flux-system get kustomization infra"
if ! $KS >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization infra does not exist."
  exit 1
fi
PATH_FIELD="$($KS -o jsonpath='{.spec.path}')"
PRUNE="$($KS -o jsonpath='{.spec.prune}')"
SUSPEND="$($KS -o jsonpath='{.spec.suspend}')"
READY="$($KS -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
CHECKS="$($KS -o jsonpath='{range .spec.healthChecks[*]}{.kind}/{.namespace}/{.name}{"\n"}{end}')"

case "$PATH_FIELD" in
  ./infrastructure|infrastructure|./infrastructure/) ;;
  *) echo "FAIL: infra applies '$PATH_FIELD', expected ./infrastructure."; exit 1 ;;
esac
[ "$PRUNE" = "true" ] || { echo "FAIL: prune must stay true on infra."; exit 1; }
[ "$SUSPEND" != "true" ] || { echo "FAIL: infra is suspended."; exit 1; }
if ! printf '%s\n' "$CHECKS" | grep -qx 'Deployment/platform/cache'; then
  echo "FAIL: infra must keep a health check on Deployment cache in the namespace platform."
  exit 1
fi
[ "$READY" = "True" ] || { echo "FAIL: infra is not Ready (Ready=$READY)."; exit 1; }
echo "PASS: infra is Ready and checks Deployment cache in platform."
exit 0
