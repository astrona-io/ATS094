#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

kubectl -n flux-system scale deployment kustomize-controller --replicas=1
kubectl -n flux-system rollout status deployment/kustomize-controller --timeout=180s

kubectl -n flux-system patch gitrepository fleet --type merge \
  -p '{"spec":{"url":"http://gitea.localtest.me:3000/gitops/fleet.git"}}'

flux reconcile kustomization podinfo --with-source --timeout=5m
