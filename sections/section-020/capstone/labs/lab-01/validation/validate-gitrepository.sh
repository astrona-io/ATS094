#!/usr/bin/env bash
# PASS when the GitRepository fleet points at gitops/fleet.git, is Ready, and
# holds an artifact of the main branch.
set -uo pipefail

NS="flux-system"
EXPECTED_URL="http://gitea.localtest.me:3000/gitops/fleet.git"

url="$(kubectl -n "$NS" get gitrepository fleet -o jsonpath='{.spec.url}' 2>/dev/null)"
if [ "$url" != "$EXPECTED_URL" ]; then
  echo "FAIL: GitRepository fleet has the URL '$url', expected $EXPECTED_URL."
  exit 1
fi

ready="$(kubectl -n "$NS" get gitrepository fleet \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  message="$(kubectl -n "$NS" get gitrepository fleet \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null)"
  echo "FAIL: GitRepository fleet is not Ready. Message: $message"
  exit 1
fi

revision="$(kubectl -n "$NS" get gitrepository fleet -o jsonpath='{.status.artifact.revision}' 2>/dev/null)"
case "$revision" in
  main@sha1:*) ;;
  *) echo "FAIL: GitRepository fleet has no artifact of main (revision: '${revision:-none}')."; exit 1 ;;
esac

echo "PASS: GitRepository fleet is Ready with artifact $revision."
exit 0
