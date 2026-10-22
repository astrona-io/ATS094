# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Bootstrapping Flux

## Scenario

This cluster was bootstrapped from `gitops/fleet` and ran podinfo from Git without trouble. Then three things happened on the same afternoon:

- The security team rotated the password of the Gitea user `gitops`. The new password is `gitops-password-rotated`. Nobody told the cluster.
- Someone tried a quick fix with `kubectl` on the `flux-system` objects.
- A colleague pushed a change to `clusters/kind/podinfo.yaml`.

Now `flux get all -A` shows objects that are not `Ready`, and new commits to `gitops/fleet` no longer reach the cluster.

## Your task

Make Flux follow `gitops/fleet` again, from the source to the application.

1. Find every reason the `flux-system` `GitRepository` and `Kustomization` are not `Ready`, and fix them.
2. Once Flux reads the latest commit, find why the `podinfo` Kustomization fails, and fix it in Git.
3. Prove that Flux manages itself again and applies what is on `main`.

## Constraints

- Keep the new password. Do not set the Gitea password back to `gitops-password`.
- Do not uninstall Flux or delete the `flux-system` namespace.
- Fix the podinfo problem in Git, not with `kubectl patch` or `kubectl edit`.
- Do not change the files under `apps/podinfo`.

## Done when

- The `GitRepository` `flux-system` is `Ready` at the latest commit on `main`.
- The `Kustomization` `flux-system` syncs `./clusters/kind`, is `Ready`, and has applied that commit.
- `clusters/kind/podinfo.yaml` in Git uses the path `./apps/podinfo`, the `Kustomization` `podinfo` is `Ready`, and the `podinfo` Deployment has ready pods.
- Gitea accepts only the rotated password for `gitops`.
