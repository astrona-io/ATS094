#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-030-02.
#
# Creates the Git credentials Secret, then applies a GitRepository and three
# Flux Kustomizations that stand in for a cluster entry point. Three things are
# wrong. The corrected objects are NOT applied here - producing them is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password

echo "[lab] Applying the Flux objects..."
kubectl apply -f "$MANIFESTS/broken-entrypoints.yaml"

echo "[lab] Waiting for the source..."
kubectl -n flux-system wait gitrepository/fleet --for=condition=Ready --timeout=3m || true

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] The cluster does not run the repository layout yet. Finding out why is the task."
