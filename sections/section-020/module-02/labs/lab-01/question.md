# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Git sources, references and credentials

## Scenario

The repository `gitops/fleet` holds the application in the folder `apps/podinfo`. The commit that the team reviewed is marked with the Git tag `release-1`. After that tag, someone pushed one more commit to the branch `main` that adds a second Deployment, `unreviewed`, which nobody approved.

A colleague created a `GitRepository` `fleet` and a Flux `Kustomization` `podinfo` in the namespace `flux-system`. The Secret `fleet-auth` holds working credentials. Nothing is deployed, and the `GitRepository` is not ready.

## Your task

1. Find out why the `GitRepository` `fleet` is not ready.
2. Make Flux deploy only the reviewed state of the application: the state at the tag `release-1`.
3. Confirm that the Deployment `podinfo` runs and the Deployment `unreviewed` does not exist.

## Constraints

- **Flux must apply the application.** Do not apply files with `kubectl` yourself.
- Keep the names `fleet` and `podinfo`, the repository URL, `prune: true` and the Secret `fleet-auth`.
- Do not suspend any object and do not change anything in the repository. Do not delete the tag or the extra commit.
- Do not create a second `GitRepository`.

## Done when

- `flux get sources git` shows `fleet` as `Ready` with a revision of the form `release-1@sha1:` followed by the commit hash.
- `flux get kustomizations` shows `podinfo` as `Ready` on the same revision.
- The Deployment `podinfo` in the namespace `podinfo` was applied by Flux and runs 2 ready replicas, and no Deployment `unreviewed` exists.
