#!/usr/bin/env bash
# PASS when no Deployment named podinfo exists outside the namespace podinfo,
# the namespace staging was not created, and targetNamespace is empty or podinfo.
set -uo pipefail

OTHERS="$(kubectl get deployments -A -o jsonpath='{range .items[?(@.metadata.name=="podinfo")]}{.metadata.namespace}{"\n"}{end}' 2>/dev/null | grep -vx 'podinfo' | grep -v '^$' || true)"
if [ -n "$OTHERS" ]; then
  echo "FAIL: a Deployment podinfo exists outside the namespace podinfo: $(printf '%s' "$OTHERS" | tr '\n' ' ')."
  exit 1
fi
if kubectl get namespace staging >/dev/null 2>&1; then
  echo "FAIL: the namespace staging exists. The application belongs in podinfo; do not create staging."
  exit 1
fi
TARGET="$(kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.targetNamespace}' 2>/dev/null)"
case "$TARGET" in
  ""|podinfo) ;;
  *) echo "FAIL: targetNamespace is '$TARGET', expected it empty or podinfo."; exit 1 ;;
esac
echo "PASS: the application runs only in the namespace podinfo."
exit 0
