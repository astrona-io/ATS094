# Summary

Flux is a set of manifests. A bootstrapped cluster upgrades, customizes and recovers through Git. A cluster installed with `flux install` does the same with the CLI.

Before an upgrade, run `flux check --pre`, read the release notes, and compare `flux version` with the target. Upgrade a test cluster first. Upgrade the CLI first and the controllers second. In a bootstrapped cluster, run bootstrap again with the new CLI; the commit that changes `gotk-components.yaml` can be reverted.

Customize with `flux install` flags for components, network policies and the registry. Use patches in `kustomization.yaml` next to the components for arguments such as `--concurrent`, for resources and for multi-tenant options. Patches in Git survive an upgrade. Edits with `kubectl` do not.

Deleting a Flux `Kustomization` with pruning on deletes its applied objects. To keep them, turn pruning off first. `flux uninstall` removes the finalizers first, so workloads stay. Use `--dry-run` to preview and `--keep-namespace` to keep the namespace and what is in it.

A rebuild needs Git, plus whatever is not in Git: Secrets, data, and objects created by hand. `flux export` saves the objects.

The key facts to remember are these:

- `flux check --pre` before, `flux check` after.
- Patches in Git are the safe way to customize.
- Never delete a pruning Flux `Kustomization` to stop managing an application.
- `flux uninstall --keep-namespace --silent` removes Flux and keeps the workloads.
- Rehearse a rebuild before you need it.

<!-- astrona:playground:destroy -->
