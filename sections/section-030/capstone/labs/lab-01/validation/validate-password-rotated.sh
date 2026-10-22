#!/usr/bin/env bash
# PASS when the Gitea user gitops still uses the rotated password: the task is
# to update Flux, not to put the old password back.
set -uo pipefail

API="http://gitea-http.gitea:3000/api/v1/user"

status_with() {
  kubectl -n gitea exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}' -u "gitops:$1" "$API" 2>/dev/null
}

if [ "$(status_with gitops-password)" = "200" ]; then
  echo "FAIL: the old password gitops-password works again. Keep the rotated password and update Flux instead."
  exit 1
fi
if [ "$(status_with gitops-password-rotated)" != "200" ]; then
  echo "FAIL: the rotated password gitops-password-rotated no longer signs in to Gitea."
  exit 1
fi

echo "PASS: Gitea accepts only the rotated password for gitops."
exit 0
