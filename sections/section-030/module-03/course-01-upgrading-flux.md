# Upgrading Flux

A Flux upgrade replaces the controller images and the custom resource definitions. The applied workloads are not touched. This part shows the checks to make, the two ways to upgrade, and how to go back.

The commands below need nothing more than the running cluster:

<!-- astrona:playground:renew -->

## Two versions to compare

The `flux` command-line tool has a version, and so do the controllers in the cluster. They are installed together, and each release of the tool carries the controller versions that match it.

```sh
flux version
flux version --client
```

Without `--client`, the command also reads the controller versions from the cluster. An upgrade is done when the two match the release you want.

## Check before you change anything

```sh
flux check --pre
flux check
kubectl get nodes
```

`flux check --pre` tests the prerequisites: the Kubernetes version that the tool supports and a working connection. `flux check` tests the controllers that are installed. Run both before an upgrade. Run `flux check` again afterwards.

Before you upgrade, also read the release notes of every version between yours and the target. They list changed defaults, removed API versions and new flags. Custom resources written with a removed API version must be updated in Git before the upgrade, not after.

## Upgrade with the CLI

For a cluster installed with `flux install`, download a newer `flux` binary and run the install again. The command applies the manifests of its own version, which updates the controllers and the definitions in place:

```sh
flux install --export > flux-components.yaml
kubectl apply -f flux-components.yaml
flux check
```

`--export` prints the manifests instead of applying them. Saving them first lets you review and keep what was applied. Running `flux install` without `--export` does the apply for you. Pass the same flags as the first time, or the cluster loses any component or option that you added with a flag.

## Upgrade a bootstrapped cluster

In a cluster set up with `flux bootstrap`, the manifests live in Git, in `clusters/<name>/flux-system/gotk-components.yaml`. Upgrade by running the same bootstrap command with the new CLI:

```sh
flux bootstrap git --url=<same url> --branch=main --path=clusters/<name> ...
```

The command rewrites `gotk-components.yaml` with the new version and pushes a commit. The running Flux then applies the commit to itself. Nothing is applied from your machine except the push. Because the commit is in Git, it can be reviewed and reverted like any other change. A `kustomization.yaml` that you added next to the components is kept, which is how customizations survive an upgrade.

Automations can open the pull request for you: a CI job installs the latest CLI, runs `flux install --export` or bootstrap, and proposes the change.

## Going back

To go back, revert the commit that changed `gotk-components.yaml`. Flux applies the older controllers. The definitions are replaced with the older ones, but objects that were stored with a newer API version can stay stored in that version. Test the upgrade on a copy of the cluster first, and read the release notes for downgrade warnings.

## Upgrade order

Upgrade the cluster in this order:

1. A test cluster, then a staging cluster, then production.
2. The CLI first, then the controllers.
3. Check the `Ready` state of every source, Flux `Kustomization` and `HelmRelease` after the controllers are back.

## Try it

1. Run `flux version` and `flux check --pre`. Which versions do you see?
2. Run `flux install --export > flux-components.yaml`. How many Deployments are in the file? Which controllers are they?
3. Run `kubectl apply -f flux-components.yaml` and then `flux check`. What changed in the cluster? Check with `kubectl -n flux-system get pods`.
