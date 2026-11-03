# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Environments in Git

## Scenario

The repository `gitops/fleet` describes one application in two environments. The folder `apps/podinfo/base` holds what both share. The folders `apps/podinfo/overlays/staging` and `apps/podinfo/overlays/production` each change a few values: staging runs 1 replica with the message `staging`, and production runs 2 replicas with the message `production`. The folder `infrastructure/namespaces` creates the namespaces `staging` and `production`.

Four Flux objects in the namespace `flux-system` apply this: the `GitRepository` `fleet` and the Flux `Kustomization` objects `namespaces`, `staging` and `production`. Staging works. Production applies without an error, but it does not run its own configuration.

## Your task

1. Find out what the Flux `Kustomization` `production` applies, and where.
2. Fix the object so that production runs the production overlay in the namespace `production`. There is more than one cause.
3. Confirm that both environments run their own configuration, side by side.

## Constraints

- **Flux must apply the environments.** Do not apply files with `kubectl` yourself.
- Do not change the repository, the `staging` and `namespaces` objects, or the names of any object.
- Do not suspend any object and do not delete the Deployment by hand.

## Done when

- `flux get kustomizations` shows `namespaces`, `staging` and `production` as `Ready`.
- The Deployment `podinfo` in the namespace `production` runs 2 ready replicas and has the message `production`.
- The Deployment `podinfo` in the namespace `staging` still runs 1 replica with the message `staging`.
