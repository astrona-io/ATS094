#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-020-06.
#
# Creates the Git credentials Secret, then applies a GitRepository, a Flux
# Kustomization that deploys podinfo 6.5.0 (the Deployment carries an image
# policy marker), an ImageRepository, an ImagePolicy with a range that matches
# nothing, and an ImageUpdateAutomation with the wrong path. The corrected
# objects are NOT applied here - producing them is the task. The image registry
# ghcr.io needs outbound internet access.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Waiting for the image automation controllers..."
kubectl -n flux-system wait deployment/image-reflector-controller deployment/image-automation-controller \
  --for=condition=Available --timeout=300s

echo "[lab] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password

echo "[lab] Applying the Flux objects..."
kubectl apply -f "$MANIFESTS/broken-automation.yaml"

echo "[lab] Waiting for podinfo to be applied..."
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=5m || true

echo "[lab] Starting state ready."
flux get kustomizations || true
flux get image all || true
echo "[lab] podinfo runs 6.5.0 and nothing updates it. Finding out why is the task."
