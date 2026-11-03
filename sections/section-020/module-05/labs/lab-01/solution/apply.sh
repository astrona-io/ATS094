#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch alerts.notification.toolkit.fluxcd.io app-events --type=merge -p '{
  "spec": {
    "providerRef": {"name": "team-webhook"},
    "eventSeverity": "info",
    "eventSources": [
      {"kind": "Kustomization", "name": "podinfo", "namespace": "flux-system"},
      {"kind": "GitRepository", "name": "fleet", "namespace": "flux-system"}
    ]
  }
}'
sleep 5
