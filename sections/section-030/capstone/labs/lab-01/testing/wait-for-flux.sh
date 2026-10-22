#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# Waits for Gitea and the four default Flux controllers. The flux-system objects
# are broken on purpose, so this does not wait for them to be Ready.
set -eu

kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n gitea rollout status deployment/tester --timeout=300s
for controller in source-controller kustomize-controller helm-controller notification-controller; do
  kubectl -n flux-system rollout status "deployment/$controller" --timeout=300s
done
for _ in $(seq 1 60); do
  if kubectl -n gitea exec deploy/tester -- \
       curl -fsS http://gitea-http.gitea:3000/api/healthz >/dev/null 2>&1; then
    exit 0
  fi
  sleep 2
done
echo "Gitea did not answer on /api/healthz." >&2
exit 1
