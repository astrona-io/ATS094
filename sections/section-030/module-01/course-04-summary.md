# Summary

A cluster is only run from Git when Git also describes Flux itself. `flux bootstrap` makes that true, and this module showed what it does, how to check it, and what keeps it working.

## What you learned

`flux install` puts the Flux controllers in a cluster and stops there; it is for development and tests. `flux bootstrap` installs the same controllers, but first writes them to Git. It clones the repository, writes `gotk-components.yaml` with the controllers and CRDs, installs them, stores a credential in the Secret `flux-system`, writes `gotk-sync.yaml` with the `GitRepository` and the Flux `Kustomization` named `flux-system`, plus the Kustomize file `kustomization.yaml` that lists both, and pushes everything to `<path>/flux-system`. Provider commands such as `flux bootstrap github` also create the repository and register a deploy key; `flux bootstrap git` works with any server but needs an existing repository.

Because the `flux-system` Kustomization applies the path that holds `flux-system/`, Flux applies its own manifests on every reconciliation. Upgrading Flux is a commit, and running bootstrap again is safe: it is idempotent. A bootstrap is proven from three sides. `flux check` shows healthy controllers, the CRDs ending in `toolkit.fluxcd.io` are present, and `flux get all -A` shows the `flux-system` objects `Ready` at the commit bootstrap pushed. An application then arrives through Git: a Flux `Kustomization` committed under the synced path, pointing at the application's folder in the same `GitRepository`.

The credential is the one part that is not in Git. With token authentication, the Secret `flux-system` holds `username` and `password`; with SSH, it holds `identity`, `identity.pub` and `known_hosts`, and the public key is registered as a deploy key on one repository. A read-only deploy key is enough for syncing. When a credential is rotated, the source stops being `Ready` while the Kustomizations keep applying the last artifact, so the failure is easy to miss. `flux create secret git` or a new run of `flux bootstrap` puts the new credential in place. The key facts to remember are these:

- Bootstrap writes three files under `<path>/flux-system`: `gotk-components.yaml`, `gotk-sync.yaml` and `kustomization.yaml`.
- The `flux-system` Kustomization applies Flux's own manifests, so Flux manages itself.
- Running bootstrap again is safe; with a newer CLI, it upgrades Flux.
- The Git credential lives only in the Secret `flux-system`, never in Git.
- After a credential failure, check the `GitRepository` and its revision, not only the Kustomizations.

<!-- astrona:playground:destroy -->
