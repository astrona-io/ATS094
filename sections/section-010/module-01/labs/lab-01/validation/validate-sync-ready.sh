#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo applies ./apps/podinfo from fleet,
# is Ready on a main revision, is not suspended, and still prunes.
set -uo pipefail

NS="flux-system"
KS="kubectl -n $NS get kustomization podinfo"

if ! $KS >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization podinfo does not exist in $NS."
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
  *) echo "FAIL: podinfo applies the path '$PATH_FIELD'; the application is in ./apps/podinfo."; exit 1 ;;
esac
if [ "$SOURCE" != "GitRepository/fleet" ]; then
  echo "FAIL: podinfo must use the GitRepository fleet (found: $SOURCE)."
  exit 1
fi
if [ "$PRUNE" != "true" ]; then
  echo "FAIL: prune must stay true on podinfo."
  exit 1
fi
if [ "$SUSPEND" = "true" ]; then
  echo "FAIL: podinfo is suspended. A suspended Flux Kustomization applies nothing."
  exit 1
fi
if [ "$READY" != "True" ]; then
  echo "FAIL: the Flux Kustomization podinfo is not Ready (Ready=$READY)."
  exit 1
fi
case "$APPLIED" in
  main@sha1:*) ;;
  *) echo "FAIL: the last applied revision is '$APPLIED', expected main@sha1:<commit>."; exit 1 ;;
esac

echo "PASS: the Flux Kustomization podinfo applied $APPLIED."
exit 0
