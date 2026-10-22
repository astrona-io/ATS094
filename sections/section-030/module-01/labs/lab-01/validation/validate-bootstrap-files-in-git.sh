#!/usr/bin/env bash
# PASS when gitops/fleet holds the manifests flux bootstrap writes under
# clusters/kind/flux-system, so Flux manages itself from Git.
set -uo pipefail

GIT_AUTH="gitops:gitops-password"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents"

for file in gotk-components.yaml gotk-sync.yaml kustomization.yaml; do
  CODE="$(kubectl -n gitea exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}' -u "$GIT_AUTH" "$API/clusters/kind/flux-system/$file" 2>/dev/null)"
  if [ "$CODE" != "200" ]; then
    echo "FAIL: clusters/kind/flux-system/$file is not in gitops/fleet on main (HTTP $CODE)."
    exit 1
  fi
done

echo "PASS: gitops/fleet holds gotk-components.yaml, gotk-sync.yaml and kustomization.yaml under clusters/kind/flux-system."
exit 0
