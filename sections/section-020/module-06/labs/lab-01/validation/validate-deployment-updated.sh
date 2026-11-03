#!/usr/bin/env bash
# PASS when the Deployment podinfo runs the tag selected by the ImagePolicy, the
# tag is not 6.5.0, and Flux applied it.
set -uo pipefail

P="kubectl -n flux-system get imagepolicy podinfo"
WANT="$($P -o jsonpath='{.status.latestRef.tag}' 2>/dev/null)"
if [ -z "$WANT" ]; then
  IMG="$($P -o jsonpath='{.status.latestImage}' 2>/dev/null)"
  WANT="${IMG##*:}"
fi
[ -n "$WANT" ] || { echo "FAIL: the ImagePolicy has no selected tag yet."; exit 1; }
D="kubectl -n podinfo get deployment podinfo"
GOT="$($D -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
READY="$($D -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
OWNER="$($D -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"
[ "${GOT##*:}" = "$WANT" ] || { echo "FAIL: the Deployment runs '$GOT', expected the tag $WANT."; exit 1; }
[ "$WANT" != "6.5.0" ] || { echo "FAIL: the tag is still 6.5.0."; exit 1; }
[ "$OWNER" = "podinfo" ] || { echo "FAIL: the Deployment is not applied by the Flux Kustomization podinfo."; exit 1; }
[ "${READY:-0}" -ge 1 ] || { echo "FAIL: the Deployment has no ready replica yet."; exit 1; }
echo "PASS: the Deployment runs $GOT, applied by Flux."
exit 0
