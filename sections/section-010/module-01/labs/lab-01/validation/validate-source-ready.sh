#!/usr/bin/env bash
# PASS when the GitRepository fleet follows main, still points at gitops/fleet,
# is Ready, and holds an artifact of a main commit.
set -uo pipefail

NS="flux-system"
GITREPO="kubectl -n $NS get gitrepository fleet"

if ! $GITREPO >/dev/null 2>&1; then
  echo "FAIL: the GitRepository fleet does not exist in $NS."
  exit 1
fi

URL="$($GITREPO -o jsonpath='{.spec.url}')"
BRANCH="$($GITREPO -o jsonpath='{.spec.ref.branch}')"
READY="$($GITREPO -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
REVISION="$($GITREPO -o jsonpath='{.status.artifact.revision}')"

if [ "$URL" != "http://gitea.localtest.me:3000/gitops/fleet.git" ]; then
  echo "FAIL: fleet must still point at http://gitea.localtest.me:3000/gitops/fleet.git (found: $URL)."
  exit 1
fi
if [ "$BRANCH" != "main" ]; then
  echo "FAIL: fleet follows the branch '$BRANCH'; the repository's branch is main."
  exit 1
fi
if [ "$READY" != "True" ]; then
  echo "FAIL: the GitRepository fleet is not Ready (Ready=$READY)."
  exit 1
fi
case "$REVISION" in
  main@sha1:*) ;;
  *) echo "FAIL: the artifact revision is '$REVISION', expected main@sha1:<commit>."; exit 1 ;;
esac

echo "PASS: the GitRepository fleet is Ready at $REVISION."
exit 0
