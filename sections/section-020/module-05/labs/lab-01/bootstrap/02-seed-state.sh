#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-020-05.
#
# Creates the Git credentials Secret, a GitRepository and a Flux Kustomization
# that deploy podinfo, a generic Provider, and an Alert with a wrong
# providerRef, wrong event source namespaces and a wrong severity. The corrected
# Alert is NOT applied here - producing it is the task.
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
kubectl apply -f "$MANIFESTS/broken-alerts.yaml"

echo "[lab] Waiting for podinfo to be applied..."
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=4m || true

echo "[lab] Starting state ready."
flux get kustomizations || true
kubectl -n flux-system get providers.notification.toolkit.fluxcd.io,alerts.notification.toolkit.fluxcd.io || true
echo "[lab] The Alert is not working as intended. Finding out why is the task."
