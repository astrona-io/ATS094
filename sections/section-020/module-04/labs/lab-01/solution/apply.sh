#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch helmrelease podinfo --type=merge \
  -p '{"spec":{"chart":{"spec":{"version":"6.x"}},"values":{"replicas":null,"replicaCount":2}}}'

flux reconcile helmrelease podinfo --with-source --timeout=5m
