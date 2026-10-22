#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Wait until Gitea answers and
# every Flux controller that exists is Available, so the reference solution
# never races a controller that is still starting.
set -eu

kubectl -n gitea rollout status deployment/gitea --timeout=300s
for deployment in $(kubectl -n flux-system get deployment -o name); do
  replicas="$(kubectl -n flux-system get "$deployment" -o jsonpath='{.spec.replicas}')"
  # A controller scaled to zero on purpose has nothing to wait for.
  [ "$replicas" = "0" ] && continue
  kubectl -n flux-system rollout status "$deployment" --timeout=300s
done
