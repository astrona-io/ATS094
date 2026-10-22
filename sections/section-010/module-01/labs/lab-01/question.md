# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** The reconciliation loop

## Scenario

A colleague connected the cluster to the repository `gitops/fleet` and created two Flux objects in the namespace `flux-system`: the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo`. Both applied without an error. The repository holds the `podinfo` application in the folder `apps/podinfo`, on the branch `main`.

An hour later, the namespace `podinfo` still does not exist:

```sh
kubectl get namespace podinfo
```

## Your task

1. Find out why the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` are not ready. Read the reason each one reports.
2. Fix both objects so that Flux deploys `podinfo` from the repository.
3. Confirm that both objects are `Ready` on a revision of the branch `main`, and that the Deployment `podinfo` runs the number of replicas set in Git.

## Constraints

- **Flux must apply the application.** Do not apply the files from `apps/podinfo` with `kubectl` yourself.
- Keep the names `fleet` and `podinfo`, the repository URL and the Secret `fleet-auth`. Do not create a second `GitRepository` or Flux `Kustomization`.
- Do not suspend the Flux `Kustomization`, and keep `prune: true`.
- Do not change anything in the repository.

## Done when

- `flux get sources git` shows `fleet` as `Ready` on a `main@sha1:` revision.
- `flux get kustomizations` shows `podinfo` as `Ready`, applying the same revision.
- The Deployment `podinfo` in the namespace `podinfo` was applied by Flux and runs 2 ready replicas.
