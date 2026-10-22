#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo is not suspended, prunes, still uses
# the GitRepository fleet and ./apps/podinfo, is Ready, and has applied the
# latest revision that source-controller fetched.
set -uo pipefail

KS="kubectl -n flux-system get kustomization podinfo"
if ! $KS >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization podinfo does not exist in flux-system."
  exit 1
fi

SUSPEND="$($KS -o jsonpath='{.spec.suspend}')"
PRUNE="$($KS -o jsonpath='{.spec.prune}')"
SOURCE="$($KS -o jsonpath='{.spec.sourceRef.kind}/{.spec.sourceRef.name}')"
PATH_FIELD="$($KS -o jsonpath='{.spec.path}')"
READY="$($KS -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
APPLIED="$($KS -o jsonpath='{.status.lastAppliedRevision}')"
FETCHED="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}' 2>/dev/null)"
URL="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.url}' 2>/dev/null)"

if [ "$SUSPEND" = "true" ]; then
  echo "FAIL: podinfo is still suspended."
  exit 1
fi
if [ "$PRUNE" != "true" ]; then
  echo "FAIL: prune is not true on podinfo, so objects removed from Git stay in the cluster."
  exit 1
fi
if [ "$SOURCE" != "GitRepository/fleet" ] || [ "$URL" != "http://gitea.localtest.me:3000/gitops/fleet.git" ]; then
  echo "FAIL: podinfo must keep using the GitRepository fleet on gitops/fleet (found $SOURCE, $URL)."
  exit 1
fi
case "$PATH_FIELD" in
  ./apps/podinfo|apps/podinfo|./apps/podinfo/|apps/podinfo/) ;;
  *) echo "FAIL: podinfo must keep the path ./apps/podinfo (found: $PATH_FIELD)."; exit 1 ;;
esac
if [ "$READY" != "True" ]; then
  echo "FAIL: the Flux Kustomization podinfo is not Ready (Ready=$READY)."
  exit 1
fi
if [ -z "$FETCHED" ] || [ "$APPLIED" != "$FETCHED" ]; then
  echo "FAIL: podinfo applied '$APPLIED', but the latest fetched revision is '$FETCHED'. Reconcile with the source."
  exit 1
fi

echo "PASS: podinfo is active, prunes, and applied the latest revision $APPLIED."
exit 0
