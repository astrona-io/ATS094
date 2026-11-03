#!/usr/bin/env bash
# PASS when the Alert sends events of every severity (eventSeverity info) and the
# Flux Kustomization podinfo is untouched and Ready.
set -uo pipefail

SEV="$(kubectl -n flux-system get alerts.notification.toolkit.fluxcd.io app-events -o jsonpath='{.spec.eventSeverity}' 2>/dev/null)"
[ "$SEV" = "info" ] || { echo "FAIL: eventSeverity is '$SEV', expected info."; exit 1; }
KS="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
[ "$KS" = "True" ] || { echo "FAIL: the Flux Kustomization podinfo is not Ready; do not change it."; exit 1; }
echo "PASS: the Alert sends informational events."
exit 0
