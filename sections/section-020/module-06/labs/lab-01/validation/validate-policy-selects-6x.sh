#!/usr/bin/env bash
# PASS when the ImagePolicy podinfo is Ready and its latest tag starts with 6.
set -uo pipefail

P="kubectl -n flux-system get imagepolicy podinfo"
$P >/dev/null 2>&1 || { echo "FAIL: the ImagePolicy podinfo does not exist."; exit 1; }
READY="$($P -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
TAG="$($P -o jsonpath='{.status.latestRef.tag}')"
if [ -z "$TAG" ]; then
  IMG="$($P -o jsonpath='{.status.latestImage}')"
  TAG="${IMG##*:}"
fi
SUSPEND="$($P -o jsonpath='{.spec.suspend}')"
[ "$SUSPEND" != "true" ] || { echo "FAIL: the ImagePolicy is suspended."; exit 1; }
[ "$READY" = "True" ] || { echo "FAIL: the ImagePolicy is not Ready (Ready=$READY)."; exit 1; }
case "$TAG" in
  6.*) ;;
  *) echo "FAIL: the policy selects '$TAG', expected a tag that starts with 6."; exit 1 ;;
esac
echo "PASS: the ImagePolicy selects $TAG."
exit 0
