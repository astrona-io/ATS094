#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# This lab starts without Flux, so there are no controllers to wait for yet.
# It waits for what the reference solution depends on: Gitea answering its
# API inside the cluster, and the tester pod that calls it.
set -eu

kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n gitea rollout status deployment/tester --timeout=300s
for _ in $(seq 1 60); do
  if kubectl -n gitea exec deploy/tester -- \
       curl -fsS http://gitea-http.gitea:3000/api/healthz >/dev/null 2>&1; then
    exit 0
  fi
  sleep 2
done
echo "Gitea did not answer on /api/healthz." >&2
exit 1
