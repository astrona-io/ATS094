#!/usr/bin/env bash
# PASS when the flux-system GitRepository reads gitops/fleet and the
# flux-system Kustomization syncs ./clusters/kind, and both are Ready.
set -uo pipefail

EXPECTED_URL="http://gitea.localtest.me:3000/gitops/fleet.git"
EXPECTED_PATH="./clusters/kind"

ready_status() {
  kubectl -n flux-system get "$1" flux-system \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null
}

URL="$(kubectl -n flux-system get gitrepository flux-system -o jsonpath='{.spec.url}' 2>/dev/null)"
if [ -z "$URL" ]; then
  echo "FAIL: there is no GitRepository flux-system in flux-system. Was Flux bootstrapped?"
  exit 1
fi
if [ "$URL" != "$EXPECTED_URL" ]; then
  echo "FAIL: GitRepository flux-system points at '$URL', expected '$EXPECTED_URL'."
  exit 1
fi
if [ "$(ready_status gitrepository)" != "True" ]; then
  echo "FAIL: GitRepository flux-system is not Ready."
  kubectl -n flux-system get gitrepository flux-system
  exit 1
fi

KS_PATH="$(kubectl -n flux-system get kustomization flux-system -o jsonpath='{.spec.path}' 2>/dev/null)"
if [ "$KS_PATH" != "$EXPECTED_PATH" ]; then
  echo "FAIL: Kustomization flux-system syncs path '$KS_PATH', expected '$EXPECTED_PATH'."
  exit 1
fi
if [ "$(ready_status kustomization)" != "True" ]; then
  echo "FAIL: Kustomization flux-system is not Ready."
  kubectl -n flux-system get kustomization flux-system
  exit 1
fi

echo "PASS: flux-system reads $EXPECTED_URL and syncs $EXPECTED_PATH; both objects are Ready."
exit 0
