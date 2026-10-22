#!/usr/bin/env bash
# Checks the starting state for ats-094-lab-020-01.
#
# The starting state is Flux with its four default controllers and no image
# controllers. This script only confirms that, so a lab that starts with the
# image CRDs already present (for example after a reused cluster) fails early.
# Adding the image controllers is the task.
set -euo pipefail

if kubectl get crd imagerepositories.image.toolkit.fluxcd.io >/dev/null 2>&1; then
  echo "[lab] ERROR: the image CRDs already exist; the starting state is wrong." >&2
  exit 1
fi

echo "[lab] Starting state ready."
kubectl -n flux-system get deployments
echo "[lab] Flux runs only its default controllers. Adding the image controllers is the task."
