#!/usr/bin/env bash
# Creates the starting state for ats-094-capstone-020.
#
# Two independent faults, on purpose:
#   1. the GitRepository fleet points at gitops/fleat.git, which does not exist,
#   2. kustomize-controller is scaled to zero replicas.
# It also records the UIDs of the two Flux objects in the ConfigMap
# capstone-baseline (namespace gitea), so the grader can tell a fixed object
# from a deleted and recreated one.
#
# The fixes are NOT applied here - finding and making them is the task.
set -euo pipefail

GIT_HOST="gitea.localtest.me"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Creating the Git credentials..."
flux create secret git fleet-auth --namespace flux-system \
  --url "http://${GIT_HOST}:3000/gitops/fleet.git" \
  --username gitops --password gitops-password

echo "[lab] Applying the broken Git sync..."
kubectl apply -f "$MANIFESTS/flux-sync-broken.yaml"

echo "[lab] Stopping kustomize-controller..."
kubectl -n flux-system scale deployment kustomize-controller --replicas=0
kubectl -n flux-system rollout status deployment/kustomize-controller --timeout=120s

GITREPOSITORY_UID="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.metadata.uid}')"
KUSTOMIZATION_UID="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.metadata.uid}')"
kubectl -n gitea create configmap capstone-baseline \
  --from-literal=gitrepository-uid="$GITREPOSITORY_UID" \
  --from-literal=kustomization-uid="$KUSTOMIZATION_UID" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
echo "[lab] podinfo should run from Git, and nothing reconciles. Finding out why is the task."
