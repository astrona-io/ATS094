# Uninstalling Flux

Removing Flux sounds like deleting a namespace. It is not, because Flux objects hold finalizers and own the workloads they applied. This part shows what happens in each way of removing, so that the application survives.

The commands below need the Flux `Kustomization` `podinfo`:

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
```

## Finalizers and pruning

A Flux `Kustomization` with `prune: true` has a finalizer. When you delete the object, kustomize-controller first deletes everything in its inventory, then removes the finalizer. This is garbage collection, and it is the reason for the rule: **deleting a Flux `Kustomization` with pruning on deletes the application.**

```sh
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.metadata.finalizers}{"\n"}'
```

## Remove one Flux Kustomization and keep its objects

To stop managing an application and keep it running, turn pruning off first, then delete the object:

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge -p '{"spec":{"prune":false}}'
flux delete kustomization podinfo --silent
```

The Flux `Kustomization` also has `spec.deletionPolicy`, which sets what happens to the applied objects when it is deleted. Read its values for your version with:

```sh
kubectl explain kustomization.spec.deletionPolicy
```

## Remove Flux

`flux uninstall` removes Flux as a whole:

```sh
flux uninstall --dry-run
flux uninstall --keep-namespace --silent
```

- `--dry-run` shows what would be deleted and changes nothing.
- `--keep-namespace` leaves the namespace `flux-system`. Without it, the namespace is deleted with everything in it, including Secrets and ConfigMaps that are not Flux's.
- `--silent` skips the confirmation question.

The command removes the finalizers from the Flux objects, deletes the controllers, then deletes the custom resource definitions. Because the finalizers are removed first, the applied workloads are not garbage collected and keep running, but nothing manages them any more.

Do not delete the custom resource definitions by hand. All Flux objects would be deleted at once, with their finalizers still set, and the controllers that clear the finalizers might already be gone.

## After the uninstall

- The workloads remain, with the Flux labels `kustomize.toolkit.fluxcd.io/name` and `kustomize.toolkit.fluxcd.io/namespace` still set. They are harmless, and a later Flux will adopt the objects again.
- In a bootstrapped cluster, the files in `clusters/<name>/flux-system` stay in the repository. Delete them in a commit, or a new Flux would read them.
- The deploy key or token that Flux used stays on the Git host. Delete it there.

## Try it

1. Read the finalizers of the Flux `Kustomization` `podinfo`.
2. Run `flux uninstall --dry-run` and list what it would remove. Does it list the namespace `podinfo`?
3. Save the objects first with `flux export source git --all > sources.yaml` and `flux export kustomization --all > kustomizations.yaml`. You will need them in the next part.

## Your mission: Uninstall Flux And Keep The Workload

You now know the three ways to remove Flux and what each one deletes. The graded lab runs Flux with one application and one ConfigMap that must outlive Flux. Remove Flux without losing either.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-030-03
astrona start ats-094-playground-030-03
```
