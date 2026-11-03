# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** The Kustomize controller

## Scenario

The Deployment in `apps/podinfo` of the repository `gitops/fleet` reads its message from a variable: `PODINFO_UI_MESSAGE` is set to `${ui_message}`. The value of `ui_message` is stored in the ConfigMap `cluster-vars` in the namespace `flux-system`.

A colleague created the Flux `Kustomization` `podinfo`, which applies `./apps/podinfo` from the `GitRepository` `fleet`. It applies without an error, but the application is not running in the namespace `podinfo`, and the Flux `Kustomization` is not ready.

## Your task

1. Find out why the Flux `Kustomization` `podinfo` is not ready. There is more than one cause.
2. Fix the object so that kustomize-controller replaces `${ui_message}` with the value from the ConfigMap `cluster-vars`, and deploys everything in the namespace `podinfo`.
3. Confirm that the Deployment `podinfo` has the right message in its environment and runs 2 ready replicas.

## Constraints

- **Flux must apply the application.** Do not apply the files with `kubectl` yourself.
- Keep the names `fleet` and `podinfo`, the path, `prune: true` and the ConfigMap `cluster-vars`. Do not copy the value into the Flux `Kustomization` as a literal; keep reading it from the ConfigMap.
- Do not create extra namespaces and do not suspend any object.
- Do not change anything in the repository.

## Done when

- `flux get kustomizations` shows `podinfo` as `Ready`.
- The Deployment `podinfo` in the namespace `podinfo` runs 2 ready replicas, and its `PODINFO_UI_MESSAGE` equals the value of `ui_message` in the ConfigMap `cluster-vars`.
- No Deployment `podinfo` exists in any other namespace, and the Flux `Kustomization` reads the variables from a ConfigMap.
