#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-020-04.
#
# Applies a HelmRepository and a HelmRelease with a chart version that matches
# nothing and a values key the chart does not read. The corrected HelmRelease
# is NOT applied here - producing it is the task. The chart repository needs
# outbound internet access.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying the HelmRepository and the HelmRelease..."
kubectl apply -f "$MANIFESTS/broken-release.yaml"

echo "[lab] Starting state ready."
flux get sources helm || true
flux get helmreleases || true
echo "[lab] podinfo is not running. Finding out why is the task."
