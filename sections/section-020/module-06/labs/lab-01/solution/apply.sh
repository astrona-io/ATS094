#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch imagepolicy podinfo --type=merge \
  -p '{"spec":{"policy":{"semver":{"range":"6.x"}}}}'
kubectl -n flux-system patch imageupdateautomation fleet --type=merge \
  -p '{"spec":{"update":{"path":"./apps/podinfo"}}}'

flux reconcile image repository podinfo --timeout=2m
flux reconcile image update fleet --timeout=2m
flux reconcile source git fleet --timeout=2m
flux reconcile kustomization podinfo --timeout=4m
