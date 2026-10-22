#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo is Ready, not suspended, and has
# applied the revision the GitRepository fleet currently holds.
set -uo pipefail

NS="flux-system"

suspended="$(kubectl -n "$NS" get kustomization podinfo -o jsonpath='{.spec.suspend}' 2>/dev/null)"
if [ "$suspended" = "true" ]; then
  echo "FAIL: Kustomization podinfo is suspended."
  exit 1
fi

ready="$(kubectl -n "$NS" get kustomization podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  message="$(kubectl -n "$NS" get kustomization podinfo \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null)"
  echo "FAIL: Kustomization podinfo is not Ready. Message: ${message:-no condition yet}"
  exit 1
fi

source_revision="$(kubectl -n "$NS" get gitrepository fleet -o jsonpath='{.status.artifact.revision}' 2>/dev/null)"
applied_revision="$(kubectl -n "$NS" get kustomization podinfo -o jsonpath='{.status.lastAppliedRevision}' 2>/dev/null)"
if [ -z "$applied_revision" ] || [ "$applied_revision" != "$source_revision" ]; then
  echo "FAIL: Kustomization podinfo applied '${applied_revision:-nothing}', but the source holds '$source_revision'."
  exit 1
fi

echo "PASS: Kustomization podinfo is Ready and applied $applied_revision."
exit 0
