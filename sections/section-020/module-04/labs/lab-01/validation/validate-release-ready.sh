#!/usr/bin/env bash
# PASS when the HelmRelease podinfo is Ready, not suspended, installs from the
# HelmRepository podinfo and pins a 6.x chart version.
set -uo pipefail

HR="kubectl -n flux-system get helmrelease podinfo"
if ! $HR >/dev/null 2>&1; then
  echo "FAIL: the HelmRelease podinfo does not exist in flux-system."
  exit 1
fi
READY="$($HR -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
SUSPEND="$($HR -o jsonpath='{.spec.suspend}')"
VERSION="$($HR -o jsonpath='{.spec.chart.spec.version}')"
REPO="$($HR -o jsonpath='{.spec.chart.spec.sourceRef.name}')"

[ "$SUSPEND" != "true" ] || { echo "FAIL: the HelmRelease is suspended."; exit 1; }
[ "$REPO" = "podinfo" ] || { echo "FAIL: the chart must come from the HelmRepository podinfo (found '$REPO')."; exit 1; }
case "$VERSION" in
  6|6.*|"~6"*|"^6"*|">=6"*) ;;
  *) echo "FAIL: chart version is '$VERSION', expected a 6.x version."; exit 1 ;;
esac
[ "$READY" = "True" ] || { echo "FAIL: the HelmRelease is not Ready (Ready=$READY)."; exit 1; }
echo "PASS: the HelmRelease is Ready with chart version '$VERSION'."
exit 0
