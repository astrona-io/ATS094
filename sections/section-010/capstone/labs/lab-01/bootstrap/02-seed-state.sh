#!/usr/bin/env bash
# Creates the starting state for ats-094-capstone-010.
#
# 1. Flux applies apps/podinfo once (2 replicas and a debug pod), with prune off.
# 2. The Flux Kustomization is suspended.
# 3. The Deployment is scaled to 5 by hand, so the cluster no longer matches Git.
#
# Bringing Git and the cluster back together is the task.
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

echo "[lab] Applying the Flux objects and waiting for the first apply..."
kubectl apply -f "$MANIFESTS/sync.yaml"
flux reconcile source git fleet --timeout=3m
flux reconcile kustomization podinfo --timeout=5m

echo "[lab] Suspending the Flux Kustomization podinfo..."
flux suspend kustomization podinfo

echo "[lab] Scaling podinfo by hand..."
kubectl -n podinfo scale deployment podinfo --replicas=5
kubectl -n podinfo rollout status deployment/podinfo --timeout=300s

echo "[lab] Starting state ready."
flux get kustomizations || true
kubectl -n podinfo get deployment,pod
echo "[lab] Git and the cluster disagree. Making Git the only source of truth is the task."
