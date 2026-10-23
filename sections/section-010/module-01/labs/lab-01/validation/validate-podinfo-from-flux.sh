#!/usr/bin/env bash
# PASS when Flux (not kubectl) applied the podinfo Deployment and Service, and
# the Deployment runs the 2 replicas that Git asks for.
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

INVENTORY="$(kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' 2>/dev/null)"

for entry in podinfo_podinfo_apps_Deployment podinfo_podinfo__Service; do
  if ! printf '%s\n' "$INVENTORY" | grep -qx "$entry"; then
    echo "FAIL: $entry is not in the inventory of the Flux Kustomization podinfo. Flux must apply it, not kubectl."
    exit 1
  fi
done

READY_REPLICAS=""
for _ in $(seq 1 30); do
  READY_REPLICAS="$(kubectl -n podinfo get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "$READY_REPLICAS" = "2" ] && break
  sleep 3
done
if [ "$READY_REPLICAS" != "2" ]; then
  echo "FAIL: the Deployment podinfo has ${READY_REPLICAS:-0} ready replicas; Git asks for 2."
  exit 1
fi

echo "PASS: Flux applied podinfo, and it runs 2 ready replicas."
exit 0
