#!/usr/bin/env bash
# PASS when the event sources are exactly the Kustomization podinfo and the
# GitRepository fleet, both in flux-system.
set -uo pipefail

SRC="$(kubectl -n flux-system get alerts.notification.toolkit.fluxcd.io app-events \
  -o jsonpath='{range .spec.eventSources[*]}{.kind}/{.name}/{.namespace}{"\n"}{end}' 2>/dev/null | sort)"
for want in "GitRepository/fleet/flux-system" "Kustomization/podinfo/flux-system"; do
  printf '%s\n' "$SRC" | grep -qx "$want" || { echo "FAIL: the event source $want is missing (found: $(printf '%s' "$SRC" | tr '\n' ' '))."; exit 1; }
done
COUNT="$(printf '%s\n' "$SRC" | grep -c .)"
[ "$COUNT" = "2" ] || { echo "FAIL: expected exactly 2 event sources, found $COUNT."; exit 1; }
echo "PASS: the event sources are the Kustomization podinfo and the GitRepository fleet in flux-system."
exit 0
