#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
#
# `astrona test` has no port-forward to Gitea, so the Git changes go through
# the Gitea API from the tester pod instead of `git push`. The learner does the
# same changes with a clone, a commit and a push.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

GIT_AUTH="gitops:gitops-password"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents"

file_sha() {
  # file_sha REPO_PATH: prints the blob SHA Gitea needs to change or delete a file.
  kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_AUTH' '$API/$1?ref=main' | jq -r .sha"
}

commit_file() {
  # commit_file METHOD REPO_PATH MESSAGE [CONTENT]: PUT updates, DELETE removes.
  local method="$1" path="$2" message="$3" content="${4:-}" sha body
  sha="$(file_sha "$path")"
  if [ "$method" = "PUT" ]; then
    body="{\"content\":\"$(printf '%s' "$content" | base64 | tr -d '\n')\",\"sha\":\"$sha\",\"message\":\"$message\",\"branch\":\"main\"}"
  else
    body="{\"sha\":\"$sha\",\"message\":\"$message\",\"branch\":\"main\"}"
  fi
  printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
    curl -fsS -u "$GIT_AUTH" -X "$method" -H 'Content-Type: application/json' \
    --data-binary @- "$API/$path" >/dev/null
}

# 1. Turn pruning on while the Flux Kustomization is still suspended, so the
#    first apply after the Git change deletes the debug pod.
kubectl -n flux-system patch kustomization podinfo --type=merge -p '{"spec":{"prune":true}}'

# 2. Change the desired state in Git: 3 replicas, no debug pod.
commit_file PUT apps/podinfo/deployment.yaml "Run podinfo with 3 replicas" "$(cat <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: podinfo
  labels:
    app: podinfo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
        - name: podinfo
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          env:
            - name: PODINFO_UI_MESSAGE
              value: "deployed by Flux"
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
YAML
)"
commit_file PUT apps/podinfo/kustomization.yaml "Stop deploying the debug pod" "$(cat <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
YAML
)"
commit_file DELETE apps/podinfo/debug-pod.yaml "Remove the debug pod"

# 3. Resume, and apply the new revision now.
flux resume kustomization podinfo --timeout=5m
flux reconcile kustomization podinfo --with-source --timeout=5m
# The pruned debug pod takes its 30-second grace period to stop.
kubectl -n podinfo wait --for=delete pod/debug --timeout=120s
