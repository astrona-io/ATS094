#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"branch":"main"}}}'
kubectl -n flux-system patch kustomization podinfo --type=merge \
  -p '{"spec":{"path":"./apps/podinfo"}}'

flux reconcile source git fleet --timeout=2m
flux reconcile kustomization podinfo --timeout=3m
