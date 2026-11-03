#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-030-03.
#
# Creates the Git credentials Secret, a GitRepository and a Flux Kustomization
# that runs podinfo with pruning on, a ConfigMap team-notes in flux-system, and
# a ConfigMap in default that records the UID of the podinfo Deployment. The task
# is to remove Flux without losing any of them.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

echo "[lab] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password

echo "[lab] Creating the GitRepository and the Flux Kustomization..."
flux create source git fleet \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
flux create kustomization podinfo \
  --source=GitRepository/fleet --path=./apps/podinfo \
  --prune=true --wait=true --interval=5m --timeout=4m

echo "[lab] Waiting for podinfo..."
kubectl -n podinfo rollout status deployment/podinfo --timeout=4m

echo "[lab] Recording the starting state..."
kubectl -n flux-system create configmap team-notes \
  --from-literal=note="Owned by the platform team. Do not delete."
UID_NOW="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.metadata.uid}')"
kubectl -n default create configmap lab-baseline --from-literal=deployment-uid="$UID_NOW"

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] Flux is installed and runs podinfo. Removing Flux safely is the task."
