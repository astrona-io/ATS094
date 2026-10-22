#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab starts without the image controllers.
# Taken from solution.md - if one changes, change the other.
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

flux install --components-extra=image-reflector-controller,image-automation-controller
kubectl apply -f "$SCRIPT_DIR/../manifests/imagerepository-podinfo.yaml"

# The first scan needs a moment to reach ghcr.io.
kubectl -n flux-system wait imagerepository/podinfo --for=condition=Ready --timeout=180s
