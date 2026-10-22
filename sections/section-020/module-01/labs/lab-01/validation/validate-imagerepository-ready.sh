#!/usr/bin/env bash
# PASS when the ImageRepository podinfo in flux-system scans
# ghcr.io/stefanprodan/podinfo and is Ready.
set -uo pipefail

NS="flux-system"

image="$(kubectl -n "$NS" get imagerepository podinfo -o jsonpath='{.spec.image}' 2>/dev/null)"
if [ -z "$image" ]; then
  echo "FAIL: ImageRepository podinfo does not exist in $NS."
  exit 1
fi
if [ "$image" != "ghcr.io/stefanprodan/podinfo" ]; then
  echo "FAIL: ImageRepository podinfo scans '$image', not ghcr.io/stefanprodan/podinfo."
  exit 1
fi

ready=""
for _ in $(seq 1 12); do
  ready="$(kubectl -n "$NS" get imagerepository podinfo \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && break
  sleep 5
done
if [ "$ready" != "True" ]; then
  message="$(kubectl -n "$NS" get imagerepository podinfo \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null)"
  echo "FAIL: ImageRepository podinfo is not Ready. Message: ${message:-no condition yet}"
  exit 1
fi

tags="$(kubectl -n "$NS" get imagerepository podinfo -o jsonpath='{.status.lastScanResult.tagCount}' 2>/dev/null)"
echo "PASS: ImageRepository podinfo is Ready (tags found: ${tags:-unknown})."
exit 0
