# Apps, Infrastructure And Clusters

A repository with three top-level folders is enough for one cluster and grows to many. This part shows what each folder holds and how the Flux objects connect them.

The commands below need the `GitRepository` `fleet` and a clone of the repository in the folder `fleet`:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
find fleet -type f -not -path '*/.git/*' | sort
```

## The layout

```text
apps/
  base/podinfo/          the application, with no namespace
  kind/                  the overlay for the cluster "kind"
infrastructure/
  controllers/           namespaces and custom resource definitions
  configs/               objects that need those definitions
clusters/
  kind/                  the entry point of the cluster
```

- **`apps`** holds what users run. A `base` is shared. An overlay folder per cluster or per environment changes a few values.
- **`infrastructure`** holds what applications need: ingress controllers, certificate managers, storage classes, policies. It is applied before `apps`.
- **`clusters`** holds one folder per cluster. This folder is the only one that a cluster is told about. It contains Flux `Kustomization` objects that point at the other two.

## Why infrastructure has two folders

Some objects can only be created after others. A custom resource such as a `Widget` needs its custom resource definition first. If both are in one folder, the apply can fail on a new cluster because the definition is not yet known when the `Widget` is checked.

Splitting them solves it. `controllers` creates the definitions and the namespaces. `configs` creates the objects of those kinds. The Flux `Kustomization` for `configs` waits for the one for `controllers`. This is the same pattern for an ingress controller and its issuer objects, or a policy engine and its policies.

Read the two folders:

```sh
cat fleet/infrastructure/controllers/kustomization.yaml
cat fleet/infrastructure/configs/widget.yaml
```

## The entry point

In a cluster set up with `flux bootstrap`, the folder `clusters/<name>/flux-system` holds the Flux components and a Flux `Kustomization` that applies the whole folder `clusters/<name>`. Any other file in that folder is therefore applied too. You add the Flux `Kustomization` objects for `infrastructure` and `apps` there.

With the playground you have no bootstrap, so create the same three objects by hand. Create them with `flux create` and `--export` to see the YAML that would live in `clusters/kind`:

```sh
flux create kustomization infrastructure-controllers \
  --source=GitRepository/fleet --path=./infrastructure/controllers \
  --prune=true --wait=true --interval=5m --export
```

A line of the output names the path, the source and the wait setting. Save the output of all three objects in `clusters/kind` in a real repository, and commit them. After that, adding an application is a commit and nothing else.

## Try it

1. Build the overlay with `kubectl kustomize fleet/apps/kind`. How many replicas does it set, and where does the namespace come from?
2. Create the `infrastructure-configs` Flux `Kustomization` first, without `--depends-on`, on a cluster where the definition does not exist yet. Read the `Ready` message.
3. Create `infrastructure-controllers`, wait until it is ready, and reconcile `infrastructure-configs` again. What changed?
