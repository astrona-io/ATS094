#!/usr/bin/env bash
# PASS when the flux-system GitRepository is Ready and its artifact is the
# latest commit on main in gitops/fleet, so Flux reads Git with a working
# credential again.
set -uo pipefail

GIT_AUTH="gitops:gitops-password-rotated"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet"

READY="$(kubectl -n flux-system get gitrepository flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$READY" != "True" ]; then
  echo "FAIL: GitRepository flux-system is not Ready:"
  kubectl -n flux-system get gitrepository flux-system \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
  exit 1
fi

REVISION="$(kubectl -n flux-system get gitrepository flux-system -o jsonpath='{.status.artifact.revision}')"
ARTIFACT_SHA="${REVISION##*:}"
HEAD_SHA="$(kubectl -n gitea exec deploy/tester -- sh -c \
  "curl -fsS -u '$GIT_AUTH' '$API/branches/main' | jq -r '.commit.id'" 2>/dev/null)"
if [ -z "$HEAD_SHA" ] || [ "$ARTIFACT_SHA" != "$HEAD_SHA" ]; then
  echo "FAIL: GitRepository flux-system has revision '$REVISION', but main in gitops/fleet is at '$HEAD_SHA'."
  echo "      Run 'flux reconcile source git flux-system' and check again."
  exit 1
fi

echo "PASS: GitRepository flux-system is Ready at the latest commit on main ($HEAD_SHA)."
exit 0
