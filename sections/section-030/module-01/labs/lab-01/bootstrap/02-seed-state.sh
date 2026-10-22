#!/usr/bin/env bash
# Creates the starting state for ats-094-lab-030-01.
#
# Seeds gitops/fleet with the podinfo application under apps/podinfo and an
# empty clusters/kind folder. Flux is NOT installed and nothing points at the
# repository: bootstrapping Flux and deploying podinfo through it is the task.
set -euo pipefail

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_DIR="$SCRIPT_DIR/../manifests/repo"

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

seed_file() {
  # seed_file LOCAL_FILE REPO_PATH: commits one new file to gitops/fleet on main.
  local content
  content="$(base64 < "$1" | tr -d '\n')"
  gitea_api POST "/repos/$GIT_USER/$REPO/contents/$2" \
    "{\"content\":\"$content\",\"message\":\"Add $2\",\"branch\":\"main\"}" >/dev/null
}

echo "[lab] Seeding gitops/fleet with the podinfo application..."
(cd "$SEED_DIR" && find . -type f | sed 's|^\./||') | while read -r file; do
  seed_file "$SEED_DIR/$file" "$file"
done

if kubectl get namespace flux-system >/dev/null 2>&1; then
  echo "[lab] ERROR: flux-system already exists; this lab must start without Flux." >&2
  exit 1
fi

echo "[lab] Starting state ready: Gitea holds gitops/fleet, and Flux is not installed."
echo "[lab] Start the port-forward in a second terminal before you use git or flux bootstrap:"
echo "  kubectl -n gitea port-forward svc/gitea-http 3000:3000"
