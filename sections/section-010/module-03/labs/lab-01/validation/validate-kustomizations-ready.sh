#!/usr/bin/env bash
# PASS when namespaces, staging and production are Ready and not suspended, and
# production applies the production overlay.
set -uo pipefail

for k in namespaces staging production; do
  READY="$(kubectl -n flux-system get kustomization "$k" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  SUSPEND="$(kubectl -n flux-system get kustomization "$k" -o jsonpath='{.spec.suspend}' 2>/dev/null)"
  [ "$SUSPEND" != "true" ] || { echo "FAIL: $k is suspended."; exit 1; }
  [ "$READY" = "True" ] || { echo "FAIL: the Flux Kustomization $k is not Ready (Ready=$READY)."; exit 1; }
done
P="$(kubectl -n flux-system get kustomization production -o jsonpath='{.spec.path}')"
case "$P" in
  ./apps/podinfo/overlays/production|apps/podinfo/overlays/production|./apps/podinfo/overlays/production/) ;;
  *) echo "FAIL: production applies '$P', expected ./apps/podinfo/overlays/production."; exit 1 ;;
esac
echo "PASS: all three Flux Kustomizations are Ready and production uses its overlay."
exit 0
