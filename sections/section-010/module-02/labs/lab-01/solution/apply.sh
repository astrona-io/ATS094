#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch kustomization infra --type=merge \
  -p '{"spec":{"healthChecks":[{"apiVersion":"apps/v1","kind":"Deployment","name":"cache","namespace":"platform"}]}}'
kubectl -n flux-system patch kustomization apps --type=merge \
  -p '{"spec":{"dependsOn":[{"name":"infra"}]}}'

flux reconcile kustomization infra --with-source --timeout=3m
flux reconcile kustomization apps --timeout=3m
