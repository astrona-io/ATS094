#!/usr/bin/env bash
# PASS when a Flux Kustomization named podinfo, committed to gitops/fleet under
# clusters/kind and applied by the flux-system Kustomization, is Ready and has
# deployed a ready podinfo Deployment.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

GIT_AUTH="gitops:gitops-password"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet"

if ! kubectl -n flux-system get kustomization podinfo >/dev/null 2>&1; then
  echo "FAIL: there is no Flux Kustomization podinfo in flux-system."
  exit 1
fi

# Applied from Git by the flux-system Kustomization, not with kubectl apply.
OWNER="$(kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}')"
if [ "$OWNER" != "flux-system" ]; then
  echo "FAIL: Kustomization podinfo was not applied by the flux-system Kustomization. Commit it to clusters/kind instead of applying it with kubectl."
  exit 1
fi

# The manifest is in Git under clusters/kind.
FOUND="$(kubectl -n gitea exec deploy/tester -- sh -c "
  for name in \$(curl -fsS -u '$GIT_AUTH' '$API/contents/clusters/kind' | jq -r '.[] | select(.type==\"file\") | .name'); do
    curl -fsS -u '$GIT_AUTH' '$API/raw/clusters/kind/'\"\$name\" \
      | grep -q 'kind: Kustomization' && \
    curl -fsS -u '$GIT_AUTH' '$API/raw/clusters/kind/'\"\$name\" \
      | grep -qE '^  name: podinfo\$' && echo \"\$name\"
  done" 2>/dev/null)"
if [ -z "$FOUND" ]; then
  echo "FAIL: no file directly under clusters/kind in gitops/fleet defines the Kustomization podinfo."
  exit 1
fi

KS_PATH="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.path}')"
case "$KS_PATH" in
  ./apps/podinfo|apps/podinfo|./apps/podinfo/|apps/podinfo/) ;;
  *) echo "FAIL: Kustomization podinfo syncs path '$KS_PATH', expected ./apps/podinfo."; exit 1 ;;
esac

READY="$(kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [ "$READY" != "True" ]; then
  echo "FAIL: Kustomization podinfo is not Ready."
  kubectl -n flux-system get kustomization podinfo
  exit 1
fi

DEPLOY_OWNER="$(kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"
if [ "$DEPLOY_OWNER" != "podinfo" ]; then
  echo "FAIL: the podinfo Deployment was not applied by the Flux Kustomization podinfo."
  exit 1
fi
READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}')"
if [ -z "$READY_REPLICAS" ] || [ "$READY_REPLICAS" -lt 1 ]; then
  echo "FAIL: the podinfo Deployment has no ready pods."
  exit 1
fi

echo "PASS: the Kustomization podinfo comes from clusters/kind/$FOUND, is Ready, and podinfo has $READY_REPLICAS ready pod(s)."
exit 0
