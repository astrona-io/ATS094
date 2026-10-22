#!/usr/bin/env bash
# PASS when the GitRepository fleet and the Flux Kustomization podinfo are the
# same objects the capstone started with (same UID). Rejects deleting and
# recreating them instead of fixing them.
set -uo pipefail

expected_gitrepository="$(kubectl -n gitea get configmap capstone-baseline -o jsonpath='{.data.gitrepository-uid}' 2>/dev/null)"
expected_kustomization="$(kubectl -n gitea get configmap capstone-baseline -o jsonpath='{.data.kustomization-uid}' 2>/dev/null)"
if [ -z "$expected_gitrepository" ] || [ -z "$expected_kustomization" ]; then
  echo "FAIL: the ConfigMap capstone-baseline in gitea is missing; do not delete it."
  exit 1
fi

actual_gitrepository="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.metadata.uid}' 2>/dev/null)"
actual_kustomization="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.metadata.uid}' 2>/dev/null)"

if [ "$actual_gitrepository" != "$expected_gitrepository" ]; then
  echo "FAIL: GitRepository fleet was deleted and recreated. Fix the existing object instead."
  exit 1
fi
if [ "$actual_kustomization" != "$expected_kustomization" ]; then
  echo "FAIL: Kustomization podinfo was deleted and recreated. Fix the existing object instead."
  exit 1
fi

echo "PASS: the GitRepository and the Kustomization are the original objects."
exit 0
