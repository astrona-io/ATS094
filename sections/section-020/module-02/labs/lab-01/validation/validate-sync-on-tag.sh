#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo applies ./apps/podinfo from fleet,
# prunes, is not suspended, is Ready and applied the release-1 revision.
set -uo pipefail

KS="kubectl -n flux-system get kustomization podinfo"
if ! $KS >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization podinfo does not exist."
  exit 1
fi
PATH_FIELD="$($KS -o jsonpath='{.spec.path}')"
SOURCE="$($KS -o jsonpath='{.spec.sourceRef.kind}/{.spec.sourceRef.name}')"
PRUNE="$($KS -o jsonpath='{.spec.prune}')"
SUSPEND="$($KS -o jsonpath='{.spec.suspend}')"
READY="$($KS -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
APPLIED="$($KS -o jsonpath='{.status.lastAppliedRevision}')"

case "$PATH_FIELD" in
  ./apps/podinfo|apps/podinfo|./apps/podinfo/|apps/podinfo/) ;;
  *) echo "FAIL: podinfo applies '$PATH_FIELD', expected ./apps/podinfo."; exit 1 ;;
esac
[ "$SOURCE" = "GitRepository/fleet" ] || { echo "FAIL: podinfo must use GitRepository/fleet (found: $SOURCE)."; exit 1; }
[ "$PRUNE" = "true" ] || { echo "FAIL: prune must stay true on podinfo."; exit 1; }
[ "$SUSPEND" != "true" ] || { echo "FAIL: podinfo is suspended."; exit 1; }
[ "$READY" = "True" ] || { echo "FAIL: podinfo is not Ready (Ready=$READY)."; exit 1; }
case "$APPLIED" in
  release-1@sha1:*) ;;
  *) echo "FAIL: the last applied revision is '$APPLIED', expected release-1@sha1:<commit>."; exit 1 ;;
esac
echo "PASS: podinfo applied $APPLIED."
exit 0
