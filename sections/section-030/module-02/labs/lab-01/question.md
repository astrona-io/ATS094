# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Repository structure

## Scenario

The repository `gitops/fleet` follows the usual layout for one cluster. The folder `infrastructure/controllers` creates a namespace and a custom resource definition for the kind `Widget`. The folder `infrastructure/configs` holds a `Widget` object, which needs that definition. The folder `apps` holds a shared base in `apps/base/podinfo` and an overlay for this cluster in `apps/kind`.

Three Flux `Kustomization` objects in the namespace `flux-system` stand in for the entry point of the cluster: `infrastructure-controllers`, `infrastructure-configs` and `apps`. They all apply without an error, and the cluster does not run the layout of the repository.

## Your task

1. Find out why each of the three objects does not do its job. There is more than one cause, and one fault hides behind another.
2. Fix the objects so that the infrastructure is applied first, then the configuration, then the application.
3. Confirm that the `Widget` exists and that the application runs the overlay for this cluster.

## Constraints

- **Flux must apply everything.** Do not apply files with `kubectl` yourself.
- Do not change the repository, the `GitRepository`, or the names of any object.
- Do not suspend any object and do not create objects by hand.

## Done when

- `flux get kustomizations` shows `infrastructure-controllers`, `infrastructure-configs` and `apps` as `Ready`.
- The `Widget` named `main` exists in the namespace `infra`.
- The Deployment `podinfo` in the namespace `apps` runs 2 ready replicas.
- `infrastructure-configs` is set to wait for `infrastructure-controllers`.
