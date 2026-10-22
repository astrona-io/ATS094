#!/usr/bin/env bash
# PASS when clusters/kind/podinfo.yaml in Git points at ./apps/podinfo, the
# Flux Kustomization podinfo uses that path and is Ready, and podinfo runs.
set -uo pipefail

GIT_AUTH="gitops:gitops-password-rotated"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet"

GIT_PATH_LINE="$(kubectl -n gitea exec deploy/tester -- sh -c \
  "curl -fsS -u '$GIT_AUTH' '$API/raw/clusters/kind/podinfo.yaml' | grep -E '^  path:'" 2>/dev/null)"
case "$GIT_PATH_LINE" in
  "  path: ./apps/podinfo"|"  path: apps/podinfo") ;;
  *) echo "FAIL: clusters/kind/podinfo.yaml in Git has '$GIT_PATH_LINE'; the fix belongs in Git, with path ./apps/podinfo."; exit 1 ;;
esac

KS_PATH="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.path}' 2>/dev/null)"
case "$KS_PATH" in
  ./apps/podinfo|apps/podinfo) ;;
  *) echo "FAIL: Kustomization podinfo syncs path '$KS_PATH', expected ./apps/podinfo."; exit 1 ;;
esac

READY="$(kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [ "$READY" != "True" ]; then
  echo "FAIL: Kustomization podinfo is not Ready."
  kubectl -n flux-system get kustomization podinfo
  exit 1
fi

READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
if [ -z "$READY_REPLICAS" ] || [ "$READY_REPLICAS" -lt 1 ]; then
  echo "FAIL: the podinfo Deployment has no ready pods."
  exit 1
fi

echo "PASS: Git and the cluster agree on ./apps/podinfo, the Kustomization is Ready and podinfo has $READY_REPLICAS ready pod(s)."
exit 0
