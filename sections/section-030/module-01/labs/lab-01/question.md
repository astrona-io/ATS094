# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Bootstrapping Flux

## Scenario

A new `kind` cluster must be run from Git from day one. The platform team already created the repository `gitops/fleet` on the in-cluster Gitea server. It holds the podinfo application under `apps/podinfo` and an empty folder `clusters/kind` for this cluster. Flux is not installed yet.

The Gitea address is `http://gitea.localtest.me:3000`, the user is `gitops` and the password is `gitops-password`. Gitea runs without TLS, which is only acceptable in a lab.

## Your task

1. Bootstrap Flux into the cluster from the repository `http://gitea.localtest.me:3000/gitops/fleet.git`, branch `main`, so that it syncs the path `clusters/kind`. Use the user and password above.
2. Verify the result: every Flux component healthy, the Flux custom resource definitions present, and the `flux-system` objects `Ready`.
3. Deploy podinfo through Git: commit a Flux `Kustomization` object named `podinfo` in the namespace `flux-system` to a file directly under `clusters/kind`. It must use the `GitRepository` named `flux-system` and the path `./apps/podinfo`, with pruning on.

## Constraints

- Use `flux bootstrap`. Do not install Flux with `flux install` or `kubectl apply`.
- Do not apply the `podinfo` Kustomization with `kubectl`. Flux must apply it from Git.
- Do not change the files under `apps/podinfo`.

## Done when

- `flux check` passes.
- The `GitRepository` `flux-system` points at `http://gitea.localtest.me:3000/gitops/fleet.git`, the `Kustomization` `flux-system` syncs `./clusters/kind`, and both are `Ready`.
- `gitops/fleet` holds `gotk-components.yaml`, `gotk-sync.yaml` and `kustomization.yaml` under `clusters/kind/flux-system`.
- The `Kustomization` `podinfo` is `Ready`, comes from a file directly under `clusters/kind`, and the `podinfo` Deployment in the namespace `podinfo` has ready pods.
