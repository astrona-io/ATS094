#!/usr/bin/env bash
# PASS when the GitRepository fleet uses the Secret fleet-auth, follows the tag
# release-1, still points at gitops/fleet, is Ready and holds an artifact of
# the release-1 revision.
set -uo pipefail

GR="kubectl -n flux-system get gitrepository fleet"
if ! $GR >/dev/null 2>&1; then
  echo "FAIL: the GitRepository fleet does not exist in flux-system."
  exit 1
fi
URL="$($GR -o jsonpath='{.spec.url}')"
TAG="$($GR -o jsonpath='{.spec.ref.tag}')"
BRANCH="$($GR -o jsonpath='{.spec.ref.branch}')"
SECRET="$($GR -o jsonpath='{.spec.secretRef.name}')"
SUSPEND="$($GR -o jsonpath='{.spec.suspend}')"
READY="$($GR -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
REVISION="$($GR -o jsonpath='{.status.artifact.revision}')"

case "$URL" in
  *gitops/fleet.git) ;;
  *) echo "FAIL: fleet points at '$URL', expected the repository gitops/fleet."; exit 1 ;;
esac
[ "$SECRET" = "fleet-auth" ] || { echo "FAIL: secretRef is '$SECRET', expected fleet-auth."; exit 1; }
[ "$TAG" = "release-1" ] || { echo "FAIL: ref.tag is '$TAG', expected release-1."; exit 1; }
[ -z "$BRANCH" ] || { echo "FAIL: ref.branch is still set ('$BRANCH'). Remove it."; exit 1; }
[ "$SUSPEND" != "true" ] || { echo "FAIL: fleet is suspended."; exit 1; }
[ "$READY" = "True" ] || { echo "FAIL: fleet is not Ready (Ready=$READY)."; exit 1; }
case "$REVISION" in
  release-1@sha1:*) ;;
  *) echo "FAIL: the artifact revision is '$REVISION', expected release-1@sha1:<commit>."; exit 1 ;;
esac
echo "PASS: fleet follows the tag release-1 ($REVISION)."
exit 0
