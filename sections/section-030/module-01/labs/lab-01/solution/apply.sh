#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unbootstrapped for the student.
# Taken from solution.md - if one changes, change the other.
#
# `flux bootstrap git` clones and pushes from this machine, so it needs Gitea at
# http://gitea.localtest.me:3000 here too. A learner runs the port-forward in a
# second terminal; this script starts it in the background itself and stops it
# on exit. If gitea.localtest.me does not resolve to 127.0.0.1 on this machine
# (some routers block such DNS answers), add `127.0.0.1 gitea.localtest.me` to
# /etc/hosts.
set -euo pipefail

GIT_HOST="gitea.localtest.me"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"
REPO_URL="http://${GIT_HOST}:3000/${GIT_USER}/${REPO}.git"

start_port_forward() {
  kubectl -n gitea port-forward svc/gitea-http 3000:3000 >/dev/null 2>&1 &
  PORT_FORWARD_PID=$!
  trap 'kill "$PORT_FORWARD_PID" 2>/dev/null || true' EXIT
  for _ in $(seq 1 30); do
    curl -fsS "http://${GIT_HOST}:3000/api/healthz" >/dev/null 2>&1 && return 0
    sleep 1
  done
  if curl -fsS http://127.0.0.1:3000/api/healthz >/dev/null 2>&1; then
    echo "ERROR: Gitea answers on 127.0.0.1:3000, but ${GIT_HOST} does not resolve to 127.0.0.1 here." >&2
    echo "Add this line to /etc/hosts and run again: 127.0.0.1 ${GIT_HOST}" >&2
  else
    echo "ERROR: the port-forward to Gitea did not start. Is port 3000 already in use?" >&2
  fi
  return 1
}

put_file() {
  # put_file REPO_PATH MESSAGE < CONTENT: creates or updates one file on main
  # through the Gitea API, called from the tester pod.
  local path="$1" message="$2" content sha body
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

start_port_forward

# Step 1: bootstrap Flux from gitops/fleet, syncing clusters/kind.
flux bootstrap git \
  --url="$REPO_URL" \
  --branch=main \
  --path=clusters/kind \
  --username="$GIT_USER" \
  --password="$GIT_PASSWORD" \
  --token-auth=true \
  --allow-insecure-http=true \
  --silent

# Step 2: commit a Flux Kustomization for podinfo next to flux-system.
put_file clusters/kind/podinfo.yaml "Deploy podinfo with Flux" <<'YAML'
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
  path: ./apps/podinfo
  prune: true
  wait: true
  timeout: 3m
YAML

# Step 3: pull the new commit now instead of waiting for the interval.
flux reconcile kustomization flux-system --with-source
for _ in $(seq 1 60); do
  kubectl -n flux-system get kustomization podinfo >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s
kubectl -n podinfo rollout status deployment/podinfo --timeout=300s
