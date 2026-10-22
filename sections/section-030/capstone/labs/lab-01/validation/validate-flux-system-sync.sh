#!/usr/bin/env bash
# PASS when the flux-system Kustomization syncs ./clusters/kind again, is Ready,
# and has applied the GitRepository's current revision.
set -uo pipefail

KS_PATH="$(kubectl -n flux-system get kustomization flux-system -o jsonpath='{.spec.path}' 2>/dev/null)"
if [ "$KS_PATH" != "./clusters/kind" ]; then
  echo "FAIL: Kustomization flux-system syncs path '$KS_PATH', expected './clusters/kind'."
  exit 1
fi

READY="$(kubectl -n flux-system get kustomization flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [ "$READY" != "True" ]; then
  echo "FAIL: Kustomization flux-system is not Ready."
  kubectl -n flux-system get kustomization flux-system
  exit 1
fi

APPLIED="$(kubectl -n flux-system get kustomization flux-system -o jsonpath='{.status.lastAppliedRevision}')"
SOURCE="$(kubectl -n flux-system get gitrepository flux-system -o jsonpath='{.status.artifact.revision}')"
if [ "$APPLIED" != "$SOURCE" ]; then
  echo "FAIL: Kustomization flux-system applied '$APPLIED', but the source is at '$SOURCE'."
  exit 1
fi

echo "PASS: Kustomization flux-system syncs ./clusters/kind, is Ready and applied $APPLIED."
exit 0
