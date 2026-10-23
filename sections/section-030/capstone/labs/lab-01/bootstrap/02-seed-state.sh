#!/usr/bin/env bash
# Creates the starting state for ats-094-capstone-030.
#
# First builds a healthy cluster: seeds gitops/fleet, bootstraps Flux from it
# (clusters/kind) and deploys podinfo through a Flux Kustomization committed to
# Git. Then it breaks the cluster in three independent ways:
#   1. a commit moves the podinfo Kustomization to ./apps/podinfo-v2, a path
#      that does not exist in the repository;
#   2. the Gitea password of the user gitops is rotated, while the flux-system
#      Secret still holds the old one;
#   3. the flux-system Kustomization is patched in the cluster to sync
#      ./clusters/kind-old, which does not exist, so it cannot repair itself.
# Repairing all three is the task. Nothing here repairs them.
set -euo pipefail

GIT_HOST="gitea.localtest.me"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
ROTATED_PASSWORD="gitops-password-rotated"
REPO="fleet"
REPO_URL="http://${GIT_HOST}:3000/${GIT_USER}/${REPO}.git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_DIR="$SCRIPT_DIR/../manifests/repo"

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"

start_port_forward() {
  # flux bootstrap clones and pushes from this machine, so Gitea must answer at
  # http://gitea.localtest.me:3000 here. The port-forward stops on exit.
  kubectl -n gitea port-forward svc/gitea-http 3000:3000 >/dev/null 2>&1 &
  PORT_FORWARD_PID=$!
  trap 'kill "$PORT_FORWARD_PID" 2>/dev/null || true' EXIT
  # Only Gitea's own health answer counts: another program on port 3000
  # (a dev server, Grafana) answers too, and Flux would then talk to it.
  for _ in $(seq 1 30); do
    case "$(curl -fsS "http://${GIT_HOST}:3000/api/healthz" 2>/dev/null)" in *'"status"'*pass*) true ;; *) false ;; esac && return 0
    sleep 1
  done
  if case "$(curl -fsS http://127.0.0.1:3000/api/healthz 2>/dev/null)" in *'"status"'*pass*) true ;; *) false ;; esac; then
    echo "[lab] ERROR: Gitea answers on 127.0.0.1:3000, but ${GIT_HOST} does not resolve to 127.0.0.1 here." >&2
    echo "[lab] Add this line to /etc/hosts and run again: 127.0.0.1 ${GIT_HOST}" >&2
  else
    echo "[lab] ERROR: the port-forward to Gitea did not start. Is port 3000 already in use?" >&2
  fi
  return 1
}

put_file() {
  # put_file REPO_PATH MESSAGE < CONTENT: creates or updates one file on main
  # through the Gitea API, called from the tester pod.
  local path="$1" message="$2" content sha body method
  content="$(base64 | tr -d '\n')"
  sha="$(kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$REPO/contents/$path 2>/dev/null | jq -r '.sha // empty'" || true)"
  if [ -n "$sha" ]; then
    body="{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\",\"sha\":\"$sha\"}"
    method=PUT
  else
    body="{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\"}"
    method=POST
  fi
  printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
    curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" -H 'Content-Type: application/json' \
    --data-binary @- "http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$REPO/contents/$path" >/dev/null
}

podinfo_kustomization() {
  # podinfo_kustomization PATH: prints the Flux Kustomization for podinfo.
  cat <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: $1
  prune: true
  wait: true
  timeout: 3m
YAML
}

echo "[lab] Seeding gitops/fleet with the podinfo application..."
(cd "$SEED_DIR" && find . -type f | sed 's|^\./||') | while read -r file; do
  put_file "$file" "Add $file" < "$SEED_DIR/$file"
done

echo "[lab] Bootstrapping Flux from gitops/fleet..."
start_port_forward
flux bootstrap git \
  --url="$REPO_URL" \
  --branch=main \
  --path=clusters/kind \
  --username="$GIT_USER" \
  --password="$GIT_PASSWORD" \
  --token-auth=true \
  --allow-insecure-http=true \
  --silent

echo "[lab] Deploying podinfo through Git..."
podinfo_kustomization ./apps/podinfo | put_file clusters/kind/podinfo.yaml "Deploy podinfo with Flux"
flux reconcile kustomization flux-system --with-source
for _ in $(seq 1 60); do
  kubectl -n flux-system get kustomization podinfo >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s
kubectl -n podinfo rollout status deployment/podinfo --timeout=300s

echo "[lab] Fault 1: committing a podinfo path that does not exist..."
podinfo_kustomization ./apps/podinfo-v2 | put_file clusters/kind/podinfo.yaml "Move podinfo to the v2 layout"
flux reconcile kustomization flux-system --with-source || true
flux reconcile kustomization podinfo || true

echo "[lab] Fault 2: rotating the Gitea password without updating Flux..."
kubectl -n gitea exec deploy/gitea -- gitea admin user change-password \
  --username "$GIT_USER" --password "$ROTATED_PASSWORD" --must-change-password=false

echo "[lab] Fault 3: pointing flux-system at a path that does not exist..."
kubectl -n flux-system patch kustomization flux-system --type merge \
  -p '{"spec":{"path":"./clusters/kind-old"}}'

# Make the failures visible in the status now instead of after the interval.
flux reconcile source git flux-system || true
flux reconcile kustomization flux-system || true

echo "[lab] Starting state ready. Flux no longer follows gitops/fleet."
flux get all -A || true
