#!/usr/bin/env bash
# PASS when the Flux Kustomization apps depends on infra, applies
# ./apps/podinfo, prunes, is not suspended and is Ready.
set -uo pipefail

KS="kubectl -n flux-system get kustomization apps"
if ! $KS >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization apps does not exist."
  exit 1
fi
DEPS="$($KS -o jsonpath='{range .spec.dependsOn[*]}{.name}{"\n"}{end}')"
PATH_FIELD="$($KS -o jsonpath='{.spec.path}')"
PRUNE="$($KS -o jsonpath='{.spec.prune}')"
SUSPEND="$($KS -o jsonpath='{.spec.suspend}')"
READY="$($KS -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"

if ! printf '%s\n' "$DEPS" | grep -qx 'infra'; then
  echo "FAIL: apps must list infra in spec.dependsOn (found: $(printf '%s' "$DEPS" | tr '\n' ' '))."
  exit 1
fi
case "$PATH_FIELD" in
  ./apps/podinfo|apps/podinfo|./apps/podinfo/) ;;
  *) echo "FAIL: apps applies '$PATH_FIELD', expected ./apps/podinfo."; exit 1 ;;
esac
[ "$PRUNE" = "true" ] || { echo "FAIL: prune must stay true on apps."; exit 1; }
[ "$SUSPEND" != "true" ] || { echo "FAIL: apps is suspended."; exit 1; }
[ "$READY" = "True" ] || { echo "FAIL: apps is not Ready (Ready=$READY)."; exit 1; }
echo "PASS: apps depends on infra and is Ready."
exit 0
