#!/usr/bin/env bash
# PASS when no Flux CRDs and no Flux controller Deployments remain.
set -uo pipefail

CRDS="$(kubectl get crd -o name 2>/dev/null | grep -c 'fluxcd.io' || true)"
[ "${CRDS:-0}" = "0" ] || { echo "FAIL: $CRDS Flux custom resource definitions still exist."; exit 1; }
DEPS="$(kubectl -n flux-system get deployments -o name 2>/dev/null | grep -c . || true)"
[ "${DEPS:-0}" = "0" ] || { echo "FAIL: $DEPS Deployments still run in flux-system."; exit 1; }
echo "PASS: Flux and its definitions are gone."
exit 0
