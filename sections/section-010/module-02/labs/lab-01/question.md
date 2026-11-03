# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Dependencies and health checks

## Scenario

A colleague split the repository `gitops/fleet` into two folders and created two Flux `Kustomization` objects in the namespace `flux-system`. The object `infra` applies `./infrastructure`, which holds a Deployment `cache` in the namespace `platform`. The object `apps` applies `./apps/podinfo` and must run only after `infra` is healthy. The `GitRepository` `fleet` is `Ready`.

Neither folder is fully deployed. The namespace `podinfo` does not exist, and `infra` never becomes `Ready`.

## Your task

1. Find out why `infra` is not `Ready`. Read the reason in its status conditions and in `flux events`.
2. Find out why `apps` does not start. Read the reason it reports.
3. Fix both objects so that `infra` becomes `Ready`, and `apps` applies after it and becomes `Ready` as well.

## Constraints

- **Flux must apply both folders.** Do not apply the files with `kubectl` yourself.
- Keep the names `fleet`, `infra` and `apps`, the paths, and `prune: true` on both.
- Keep a health check on the Deployment `cache` in `infra`. Do not remove it.
- Keep the dependency of `apps` on `infra`. Do not delete it.
- Do not suspend any object and do not change anything in the repository.

## Done when

- `flux get kustomizations` shows `infra` and `apps` as `Ready`.
- The Deployment `cache` in the namespace `platform` has 1 ready replica, and the Deployment `podinfo` in the namespace `podinfo` has 2 ready replicas.
- `apps` lists `infra` in `spec.dependsOn`, and `infra` has a health check on the Deployment `cache` in the namespace `platform`.
