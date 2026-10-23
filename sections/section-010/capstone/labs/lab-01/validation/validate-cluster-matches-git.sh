#!/usr/bin/env bash
# PASS when the cluster matches Git: podinfo runs 3 ready replicas, and the
# debug pod is gone from the cluster and from the Flux inventory.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

SPEC=""; READY=""
for _ in $(seq 1 40); do
  SPEC="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  READY="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "$SPEC" = "3" ] && [ "$READY" = "3" ] && break
  sleep 3
done
if [ "$SPEC" != "3" ] || [ "$READY" != "3" ]; then
  echo "FAIL: podinfo wants ${SPEC:-?} replicas with ${READY:-0} ready; Git asks for 3."
  exit 1
fi

# A pruned pod stays Terminating for its grace period (the debug container
# ignores SIGTERM, so 30 seconds); wait up to 90 seconds for it to go.
if ! kubectl -n podinfo wait --for=delete pod/debug --timeout=90s >/dev/null 2>&1; then
  echo "FAIL: the pod debug still runs in the namespace podinfo."
  exit 1
fi
if kubectl -n flux-system get kustomization podinfo \
     -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' | grep -q '^podinfo_debug__Pod$'; then
  echo "FAIL: the pod debug is still in the inventory of the Flux Kustomization podinfo."
  exit 1
fi

echo "PASS: the cluster matches Git: 3 ready replicas and no debug pod."
exit 0
