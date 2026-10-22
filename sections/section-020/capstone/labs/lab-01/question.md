# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** The GitOps Toolkit

## Scenario

The application `podinfo` is described in the Git repository `gitops/fleet` under `apps/podinfo`, and Flux is supposed to run it in the namespace `podinfo`. The `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` both exist in `flux-system`. Yet the namespace `podinfo` does not exist, and nothing changes when someone pushes to Git.

There are **two independent faults**, in the areas of two different controllers. Fixing one of them is not enough.

## Your task

1. Use the Flux tools (`flux check`, `flux get`, `flux events`, `flux logs`) to find which controller is not doing its work, and why.
2. Fix both faults.
3. Make Flux apply `podinfo` from Git, and prove that it did.

## Constraints

- **Fix the existing objects.** Do not delete and recreate the `GitRepository` `fleet` or the Flux `Kustomization` `podinfo`. The grader compares their identity with the starting state.
- The repository URL must point at `gitops/fleet` on the Git server `gitea.localtest.me:3000`. Do not create a second repository to match a wrong URL.
- Do not apply the `podinfo` manifests yourself with `kubectl`. Flux must apply them.
- Do not suspend any Flux object, and do not delete the ConfigMap `capstone-baseline` in the namespace `gitea`.

## Done when

- `kustomize-controller` has a ready replica.
- The `GitRepository` `fleet` is `Ready` with an artifact of the `main` branch.
- The Flux `Kustomization` `podinfo` is `Ready` and has applied the revision the `GitRepository` holds.
- The Deployment `podinfo` in the namespace `podinfo` was applied by the Flux `Kustomization` `podinfo` and runs two ready replicas, as Git asks.
