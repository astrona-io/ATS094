#!/usr/bin/env bash
# PASS when image-reflector-controller and image-automation-controller are
# Available in flux-system and their CRDs exist.
set -uo pipefail

NS="flux-system"
FAILED=0

for controller in image-reflector-controller image-automation-controller; do
  available="$(kubectl -n "$NS" get deployment "$controller" \
    -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)"
  if [ "$available" != "True" ]; then
    echo "FAIL: deployment $controller is not Available in $NS."
    FAILED=1
  fi
done

for crd in imagerepositories imagepolicies imageupdateautomations; do
  if ! kubectl get crd "$crd.image.toolkit.fluxcd.io" >/dev/null 2>&1; then
    echo "FAIL: CRD $crd.image.toolkit.fluxcd.io is not installed."
    FAILED=1
  fi
done

[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: both image controllers are Available and their CRDs are installed."
exit 0
