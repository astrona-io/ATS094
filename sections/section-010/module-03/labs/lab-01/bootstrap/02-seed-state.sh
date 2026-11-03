#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-010-03.
#
# Creates the Git credentials Secret, then applies a GitRepository and three
# Flux Kustomizations: namespaces, staging and production. The Flux
# Kustomization production has the wrong path and the wrong targetNamespace. The
# corrected object is NOT applied here - producing it is the task.
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
kubectl apply -f "$MANIFESTS/broken-envs.yaml"

echo "[lab] Waiting for the staging environment..."
kubectl -n flux-system wait kustomization/staging --for=condition=Ready --timeout=5m || true

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] Production does not run its own configuration. Finding out why is the task."
