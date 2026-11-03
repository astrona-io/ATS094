#!/usr/bin/env bash
# PASS when the three Flux Kustomizations are Ready and not suspended, and the
# controllers use the source fleet.
set -uo pipefail

for k in infrastructure-controllers infrastructure-configs apps; do
  READY="$(kubectl -n flux-system get kustomization "$k" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  SUSPEND="$(kubectl -n flux-system get kustomization "$k" -o jsonpath='{.spec.suspend}' 2>/dev/null)"
  [ "$SUSPEND" != "true" ] || { echo "FAIL: $k is suspended."; exit 1; }
  [ "$READY" = "True" ] || { echo "FAIL: the Flux Kustomization $k is not Ready (Ready=$READY)."; exit 1; }
done
SRC="$(kubectl -n flux-system get kustomization infrastructure-controllers -o jsonpath='{.spec.sourceRef.name}')"
[ "$SRC" = "fleet" ] || { echo "FAIL: infrastructure-controllers uses the source '$SRC', expected fleet."; exit 1; }
echo "PASS: all three Flux Kustomizations are Ready."
exit 0
