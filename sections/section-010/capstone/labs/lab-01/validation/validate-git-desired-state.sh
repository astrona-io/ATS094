#!/usr/bin/env bash
# PASS when Git, on main, asks for 3 replicas of podinfo and no longer holds the
# debug pod. Reads the repository through the Gitea API from the tester pod.
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

AUTH="gitops:gitops-password"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet"

git_file() {
  kubectl -n gitea exec deploy/tester -- curl -fsS -u "$AUTH" "$API/raw/$1?ref=main" 2>/dev/null
}

DEPLOYMENT="$(git_file apps/podinfo/deployment.yaml)"
if [ -z "$DEPLOYMENT" ]; then
  echo "FAIL: could not read apps/podinfo/deployment.yaml from gitops/fleet on main."
  exit 1
fi
GIT_REPLICAS="$(printf '%s\n' "$DEPLOYMENT" | awk '/^[[:space:]]*replicas:/{print $2; exit}')"
if [ "$GIT_REPLICAS" != "3" ]; then
  echo "FAIL: Git asks for ${GIT_REPLICAS:-no} replicas of podinfo; the task asks for 3, set in Git."
  exit 1
fi

if git_file apps/podinfo/debug-pod.yaml >/dev/null; then
  echo "FAIL: apps/podinfo/debug-pod.yaml is still in Git."
  exit 1
fi
if git_file apps/podinfo/kustomization.yaml | grep -q 'debug-pod'; then
  echo "FAIL: apps/podinfo/kustomization.yaml still lists debug-pod.yaml."
  exit 1
fi

echo "PASS: Git asks for 3 replicas of podinfo and no debug pod."
exit 0
