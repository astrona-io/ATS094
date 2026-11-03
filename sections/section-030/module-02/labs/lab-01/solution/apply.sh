#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch kustomization infrastructure-controllers --type=merge \
  -p '{"spec":{"sourceRef":{"name":"fleet"}}}'
kubectl -n flux-system patch kustomization infrastructure-configs --type=merge \
  -p '{"spec":{"dependsOn":[{"name":"infrastructure-controllers"}]}}'
kubectl -n flux-system patch kustomization apps --type=merge \
  -p '{"spec":{"path":"./apps/kind"}}'

flux reconcile source git fleet --timeout=2m
flux reconcile kustomization infrastructure-controllers --timeout=3m
flux reconcile kustomization infrastructure-configs --timeout=3m
flux reconcile kustomization apps --timeout=4m
