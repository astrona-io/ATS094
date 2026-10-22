#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-010-01.
#
# Creates the Git credentials Secret, then applies a GitRepository that follows
# a branch that does not exist and a Flux Kustomization whose path does not
# exist. podinfo is never deployed.
#
# The corrected objects are NOT applied here — producing them is the task.
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
kubectl apply -f "$MANIFESTS/broken-sync.yaml"

echo "[lab] Starting state ready."
flux get sources git || true
flux get kustomizations || true
echo "[lab] podinfo is not deployed. Finding out why is the task."
