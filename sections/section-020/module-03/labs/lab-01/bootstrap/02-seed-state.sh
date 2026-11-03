#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-020-03.
#
# Creates the Git credentials Secret and the ConfigMap cluster-vars, then
# applies a GitRepository and a Flux Kustomization with a wrong substituteFrom
# kind and a wrong targetNamespace. The corrected objects are NOT applied here -
# producing them is the task.
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

echo "[lab] Creating the ConfigMap cluster-vars..."
kubectl apply -f "$MANIFESTS/cluster-vars.yaml"

echo "[lab] Applying the Flux objects..."
kubectl apply -f "$MANIFESTS/broken-sync.yaml"

echo "[lab] Starting state ready."
flux get sources git || true
flux get kustomizations || true
echo "[lab] podinfo is not deployed. Finding out why is the task."
