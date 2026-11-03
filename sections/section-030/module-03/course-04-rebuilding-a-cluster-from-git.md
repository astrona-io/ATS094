# Rebuilding A Cluster From Git

A cluster managed with GitOps can be lost and rebuilt. This works only if everything that matters is in Git or saved somewhere else. This part lists what is not in Git and shows how to recover.

The commands below need the files `sources.yaml` and `kustomizations.yaml` saved in the earlier part. If you do not have them, create them again:

<!-- astrona:playground:renew -->

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
flux create kustomization podinfo \
  --source=GitRepository/fleet --path=./apps/podinfo \
  --prune=true --wait=true --interval=5m
flux export source git --all > sources.yaml
flux export kustomization --all > kustomizations.yaml
```

## What a rebuild needs

In a bootstrapped cluster, one command rebuilds the cluster's Flux and everything it applied: run the same `flux bootstrap` against the new cluster, with the same repository and path. Bootstrap installs the controllers, writes nothing new if the files already match, and creates the `flux-system` objects that point at the path. Flux then applies every Flux `Kustomization` in the folder.

Things that are not in Git, and need their own plan:

- **Secrets.** Credentials for the repository are created again by bootstrap. Other Secrets must come from an encrypted file in Git (SOPS), an external store, or a backup. Keep the decryption key outside the cluster.
- **Persistent data.** Volumes and databases are not in Git. Back them up with tools made for it.
- **Objects made by hand or by the CLI.** Anything created with `flux create` and not committed exists only in the cluster.
- **Operator state.** Resources that controllers create themselves are rebuilt by those controllers, or not, depending on the controller.

## Save what is not in Git

`flux export` prints Flux objects as YAML. Use it to save sources and Flux `Kustomization` objects that were created by hand:

```sh
flux export source git --all > sources.yaml
flux export kustomization --all > kustomizations.yaml
flux export helmrelease --all > helmreleases.yaml
```

The Secrets are not exported. A source that uses a Secret refers to it by name, so create the Secret again before you apply the export.

Better still, commit those files into the repository under `clusters/<name>`. Then the objects are in Git and `export` is no longer needed.

## Rebuild a non-bootstrapped cluster

A cluster installed with `flux install` is rebuilt in the same way, with the exported files:

```sh
flux install
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
kubectl apply -f sources.yaml -f kustomizations.yaml
flux get kustomizations
```

## Practise the rebuild

Rebuild on a spare cluster before you need it, and time it. Check each of these after the rebuild:

1. `flux check` reports all controllers ready.
2. `flux get sources all` shows every source ready at the latest revision.
3. `flux get kustomizations` shows every object ready.
4. The applications serve requests, and any Secrets and data are back.

## Try it

1. Run `flux uninstall --keep-namespace --silent`, then `flux install`, recreate the Secret and apply the saved files. Compare `flux get kustomizations` with the output from before.
2. Delete the Flux `Kustomization` `podinfo` with pruning turned off, apply `kustomizations.yaml`, and check that the Deployment is adopted without a restart: compare `kubectl -n podinfo get pods` before and after.
3. List three things in a cluster of your own that a rebuild would lose.
