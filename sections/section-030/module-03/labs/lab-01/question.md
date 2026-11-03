# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Uninstalling Flux

## Scenario

The platform team retires Flux from this cluster. Flux was installed with `flux install` and runs one application: a Flux `Kustomization` named `podinfo` applies the folder `apps/podinfo` of the repository `gitops/fleet`, with pruning on. The application must keep serving users while Flux goes away.

The namespace `flux-system` also holds a ConfigMap named `team-notes` that belongs to the platform team. A ConfigMap named `lab-baseline` in the namespace `default` records the identity of the running Deployment, so that the grader can tell if it was deleted and created again.

## Your task

1. Find out what happens to the applied objects when Flux is removed in different ways.
2. Remove Flux from the cluster: its controllers and its custom resource definitions.
3. Keep the application, the namespace `flux-system` and the ConfigMap `team-notes`.

## Constraints

- Do not delete the Deployment `podinfo`, its namespace or the Git server.
- Do not edit or delete the ConfigMaps `team-notes` or `lab-baseline`.
- Remove Flux with the tools of Flux, not by deleting the custom resource definitions by hand.

## Done when

- No Flux controllers run in the namespace `flux-system`, and no Flux custom resource definitions exist.
- The Deployment `podinfo` in the namespace `podinfo` still runs 2 ready replicas and is the same Deployment that ran at the start.
- The namespace `flux-system` and the ConfigMap `team-notes` still exist.
