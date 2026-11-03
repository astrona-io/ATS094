#!/usr/bin/env bash
# PASS when the ImageUpdateAutomation fleet is not suspended, still has the
# update path under apps/podinfo, and has pushed a commit.
set -uo pipefail

A="kubectl -n flux-system get imageupdateautomation fleet"
$A >/dev/null 2>&1 || { echo "FAIL: the ImageUpdateAutomation fleet does not exist."; exit 1; }
SUSPEND="$($A -o jsonpath='{.spec.suspend}')"
UPPATH="$($A -o jsonpath='{.spec.update.path}')"
COMMIT="$($A -o jsonpath='{.status.lastPushCommit}')"
[ "$SUSPEND" != "true" ] || { echo "FAIL: the ImageUpdateAutomation is suspended."; exit 1; }
case "$UPPATH" in
  ./apps/podinfo|apps/podinfo|./apps|./apps/|apps|apps/|.|./|"") ;;
  *) echo "FAIL: update.path is '$UPPATH'; it must include ./apps/podinfo."; exit 1 ;;
esac
[ -n "$COMMIT" ] || { echo "FAIL: the automation has not pushed a commit yet."; exit 1; }
echo "PASS: the automation pushed the commit $COMMIT."
exit 0
