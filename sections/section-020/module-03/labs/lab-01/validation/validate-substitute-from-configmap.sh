#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo reads its variables from the
# ConfigMap cluster-vars, applies ./apps/podinfo, prunes, is not suspended and
# is Ready.
set -uo pipefail

KS="kubectl -n flux-system get kustomization podinfo"
if ! $KS >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization podinfo does not exist."
  exit 1
fi
SOURCES="$($KS -o jsonpath='{range .spec.postBuild.substituteFrom[*]}{.kind}/{.name}{"\n"}{end}')"
PATH_FIELD="$($KS -o jsonpath='{.spec.path}')"
PRUNE="$($KS -o jsonpath='{.spec.prune}')"
SUSPEND="$($KS -o jsonpath='{.spec.suspend}')"
READY="$($KS -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"

if ! printf '%s\n' "$SOURCES" | grep -qx 'ConfigMap/cluster-vars'; then
  echo "FAIL: podinfo must read variables from ConfigMap/cluster-vars (found: $(printf '%s' "$SOURCES" | tr '\n' ' '))."
  exit 1
fi
case "$PATH_FIELD" in
  ./apps/podinfo|apps/podinfo|./apps/podinfo/|apps/podinfo/) ;;
  *) echo "FAIL: podinfo applies '$PATH_FIELD', expected ./apps/podinfo."; exit 1 ;;
esac
[ "$PRUNE" = "true" ] || { echo "FAIL: prune must stay true on podinfo."; exit 1; }
[ "$SUSPEND" != "true" ] || { echo "FAIL: podinfo is suspended."; exit 1; }
[ "$READY" = "True" ] || { echo "FAIL: podinfo is not Ready (Ready=$READY)."; exit 1; }
echo "PASS: podinfo reads its variables from the ConfigMap and is Ready."
exit 0
