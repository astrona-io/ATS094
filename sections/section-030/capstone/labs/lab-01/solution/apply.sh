#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
#
# flux bootstrap refuses to change the path of an existing flux-system
# Kustomization, so the hand-patched path goes back to ./clusters/kind first.
# Running `flux bootstrap git` again with the rotated password then rewrites
# the flux-system Secret. The podinfo path is fixed in Git.
#
# This script starts the port-forward in the background itself. If
# gitea.localtest.me does not resolve to 127.0.0.1 on this machine, add
# `127.0.0.1 gitea.localtest.me` to /etc/hosts.
set -euo pipefail

GIT_HOST="gitea.localtest.me"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password-rotated"
REPO="fleet"
REPO_URL="http://${GIT_HOST}:3000/${GIT_USER}/${REPO}.git"

start_port_forward() {
  kubectl -n gitea port-forward svc/gitea-http 3000:3000 >/dev/null 2>&1 &
  PORT_FORWARD_PID=$!
  trap 'kill "$PORT_FORWARD_PID" 2>/dev/null || true' EXIT
  # Only Gitea's own health answer counts: another program on port 3000
  # (a dev server, Grafana) answers too, and Flux would then talk to it.
  for _ in $(seq 1 30); do
    case "$(curl -fsS "http://${GIT_HOST}:3000/api/healthz" 2>/dev/null)" in *'"status"'*pass*) true ;; *) false ;; esac && return 0
    sleep 1
  done
  echo "ERROR: Gitea does not answer at http://${GIT_HOST}:3000. Check the port-forward and /etc/hosts." >&2
  return 1
}

put_file() {
  # put_file REPO_PATH MESSAGE < CONTENT: updates one file on main through the
  # Gitea API, called from the tester pod.
  local path="$1" message="$2" content sha
  content="$(base64 | tr -d '\n')"
  sha="$(kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$REPO/contents/$path | jq -r '.sha'")"
  printf '%s' "{\"content\":\"$content\",\"message\":\"$message\",\"branch\":\"main\",\"sha\":\"$sha\"}" \
    | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X PUT -H 'Content-Type: application/json' \
      --data-binary @- "http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$REPO/contents/$path" >/dev/null
}

start_port_forward

# Faults 2 and 3: flux-system back on ./clusters/kind (bootstrap refuses to
# change an existing Kustomization's path), then the new credential in the
# flux-system Secret. Bootstrap is idempotent, so this changes nothing else.
kubectl -n flux-system patch kustomization flux-system --type merge -p '{"spec":{"path":"./clusters/kind"}}'
flux bootstrap git \
  --url="$REPO_URL" \
  --branch=main \
  --path=clusters/kind \
  --username="$GIT_USER" \
  --password="$GIT_PASSWORD" \
  --token-auth=true \
  --allow-insecure-http=true \
  --silent

# Fault 1: put the podinfo path back to the folder that exists, in Git.
put_file clusters/kind/podinfo.yaml "Point podinfo back at apps/podinfo" <<'YAML'
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

flux reconcile kustomization flux-system --with-source
flux reconcile kustomization podinfo
kubectl -n flux-system wait kustomization/flux-system --for=condition=Ready --timeout=300s
kubectl -n flux-system wait kustomization/podinfo --for=condition=Ready --timeout=300s
