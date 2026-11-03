#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-020-02.
#
# The repository already holds the reviewed state of the application (the base
# seed). This script:
#   1. tags that commit `release-1`,
#   2. adds one more commit on main: the Deployment `unreviewed`,
#   3. creates the Secret fleet-auth and applies a GitRepository and a Flux
#      Kustomization that use the wrong Secret name and follow main.
# The corrected objects are NOT applied here - producing them is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

gitea_api() {
  # gitea_api METHOD PATH [JSON]: calls the Gitea API from the tester pod.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://gitea-http.gitea:3000/api/v1$path"
  else
    kubectl -n gitea exec deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" "http://gitea-http.gitea:3000/api/v1$path"
  fi
}

echo "[lab] Tagging the reviewed commit as release-1..."
if ! gitea_api GET "/repos/$GIT_USER/$REPO/tags/release-1" >/dev/null 2>&1; then
  gitea_api POST "/repos/$GIT_USER/$REPO/tags" '{"tag_name":"release-1","target":"main"}' >/dev/null
fi

echo "[lab] Adding the commit that was never reviewed to main..."
if ! gitea_api GET "/repos/$GIT_USER/$REPO/contents/apps/podinfo/unreviewed.yaml" >/dev/null 2>&1; then
  content="$(base64 < "$MANIFESTS/repo-after-tag/apps/podinfo/unreviewed.yaml" | tr -d '\n')"
  gitea_api POST "/repos/$GIT_USER/$REPO/contents/apps/podinfo/unreviewed.yaml" \
    "{\"content\":\"$content\",\"message\":\"Add the unreviewed Deployment\",\"branch\":\"main\"}" >/dev/null
fi

echo "[lab] Creating the Git credentials Secret fleet-auth..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username="$GIT_USER" --password="$GIT_PASSWORD"

echo "[lab] Applying the Flux objects..."
kubectl apply -f "$MANIFESTS/sync.yaml"

echo "[lab] Starting state ready."
flux get sources git || true
flux get kustomizations || true
echo "[lab] The source is not ready. Finding out why is the task."
