#!/usr/bin/env bash
# PASS when the Alert app-events is Ready, not suspended, and refers to the
# Provider team-webhook; the Provider is generic with its original address.
set -uo pipefail

A="kubectl -n flux-system get alerts.notification.toolkit.fluxcd.io app-events"
P="kubectl -n flux-system get providers.notification.toolkit.fluxcd.io team-webhook"
$A >/dev/null 2>&1 || { echo "FAIL: the Alert app-events does not exist."; exit 1; }
$P >/dev/null 2>&1 || { echo "FAIL: the Provider team-webhook does not exist."; exit 1; }
REF="$($A -o jsonpath='{.spec.providerRef.name}')"
READY="$($A -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
SUSPEND="$($A -o jsonpath='{.spec.suspend}')"
TYPE="$($P -o jsonpath='{.spec.type}')"
ADDR="$($P -o jsonpath='{.spec.address}')"

[ "$REF" = "team-webhook" ] || { echo "FAIL: providerRef is '$REF', expected team-webhook."; exit 1; }
[ "$SUSPEND" != "true" ] || { echo "FAIL: the Alert is suspended."; exit 1; }
[ "$TYPE" = "generic" ] || { echo "FAIL: the Provider type is '$TYPE', expected generic."; exit 1; }
[ "$ADDR" = "http://tester.gitea.svc.cluster.local:8080/flux-events" ] || { echo "FAIL: the Provider address was changed."; exit 1; }
[ "$READY" = "True" ] || { echo "FAIL: the Alert is not Ready (Ready=$READY)."; exit 1; }
echo "PASS: the Alert is Ready and uses the Provider team-webhook."
exit 0
