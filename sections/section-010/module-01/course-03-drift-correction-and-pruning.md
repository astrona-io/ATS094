# Drift Correction And Pruning

A commit is the only intended way to change the cluster, but it is not the only possible way. Anyone with `kubectl` access can scale a Deployment or delete a Service, and Git can lose a file the cluster still runs. This part shows what Flux does in both cases. It also shows the two ways to stop Flux on purpose: suspending a whole Flux `Kustomization`, and excluding one object.

The commands below need the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` in the namespace `flux-system`, with `prune: true` and the path `./apps/podinfo`. They also need your clone of `gitops/fleet` and the port-forward to Gitea running in a second terminal:

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

## Drift: a change without a commit

Drift is a difference between the live state and the desired state, for example after a manual `kubectl edit`. Create some drift on purpose. First note the replica count in Git, then scale the Deployment to one replica by hand:

```sh
grep replicas apps/podinfo/deployment.yaml
kubectl -n podinfo scale deployment podinfo --replicas=1
kubectl -n podinfo get deployment podinfo
```

The Deployment now runs one replica, and Git still says something else. Nothing reports a problem yet: kustomize-controller only looks again at its next interval. Ask it to run now:

```sh
flux reconcile kustomization podinfo
kubectl -n podinfo get deployment podinfo
```

The replica count is back to the value in Git. On every run, kustomize-controller applies the whole folder again with server-side apply, a way of applying where the Kubernetes API server merges the change and records which tool owns each field. Applying the folder sets every field Flux owns back to the value in Git, so the manual change is lost. Without `flux reconcile`, the same thing happens at the next interval of the Flux `Kustomization`.

> [!TIP]
> During an incident, a manual fix to an object that Flux manages lasts only until the next reconciliation. Either make the fix in Git, or stop Flux on purpose first, as the end of this part shows, so you know the change will stay.

## Pruning: an object that leaves Git

Drift correction handles objects that exist in Git. Pruning handles objects that have left Git. kustomize-controller keeps a list of every object it applied in the field `.status.inventory` of the Flux `Kustomization`. When an object is in that list but no longer in the new revision, and `prune` is `true`, kustomize-controller deletes it from the cluster. Read the list first:

```sh
kubectl -n flux-system get kustomization podinfo -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
```

Each entry has the form `<namespace>_<name>_<group>_<kind>`, for example `podinfo_podinfo_apps_Deployment`. Now remove the Service from Git. Delete the file, and in `apps/podinfo/kustomization.yaml` remove the line `- service.yaml` under `resources:` with an editor. Then commit, push and reconcile:

```sh
git rm apps/podinfo/service.yaml
git commit -am "Remove the podinfo Service"
git push
flux reconcile kustomization podinfo --with-source
kubectl -n podinfo get service
```

The Service `podinfo` is gone, and its entry has left the inventory. kustomize-controller deleted it because it applied it before and the new revision no longer has it. With `prune: false`, the Service would stay in the cluster and simply drop out of Flux's care, which is how forgotten objects pile up. Pruning only ever touches objects in the inventory, so an object someone created by hand is never deleted by it.

Put the Service back before you go on. The quickest way is to revert the last commit, push and reconcile:

```sh
git revert --no-edit HEAD
git push
flux reconcile kustomization podinfo --with-source
```

`git revert` creates a new commit that undoes the last one, so the history shows both the removal and the return.

## Stopping Flux on purpose

Sometimes you need Flux to leave things alone for a while, for example during an investigation. The clean way is to suspend the Flux `Kustomization`, which sets `.spec.suspend` to `true`:

```sh
flux suspend kustomization podinfo
flux get kustomizations
```

The `SUSPENDED` column now shows `True`. While a Flux `Kustomization` is suspended, kustomize-controller applies no new revisions and corrects no drift. A manual change stays, and a new commit waits. `flux resume kustomization podinfo` sets `suspend` back to `false` and reconciles at once. Run it now so the playground is back to normal.

Suspending stops a whole folder. To exclude one object, two annotations exist. `kustomize.toolkit.fluxcd.io/reconcile: disabled` on an object makes kustomize-controller stop applying changes to it and stop pruning it. You can set it in Git or on the object in the cluster; removing it from the cluster object, or setting it to `enabled` in Git, turns it back on. `kustomize.toolkit.fluxcd.io/prune: disabled` is narrower: Flux still applies the object but never deletes it, which suits an object such as a namespace that must outlive the application.

You now know what continuous reconciliation means in practice. A manual change lasts until the next run, an object removed from Git is deleted when `prune` is on, and suspending or annotating is the visible, deliberate way to make Flux stop. The open question is how all of these settings go wrong together in a real cluster, which the section capstone asks you to untangle.

## Common pitfalls

> [!WARNING]
> - **Fixing an incident with `kubectl` and walking away.** Flux reverts the change at its next interval. Make the fix in Git, or suspend the Flux `Kustomization` and say so.
> - **Turning `prune` off "to be safe".** Objects removed from Git then stay in the cluster forever, outside Flux's view. Use `kustomize.toolkit.fluxcd.io/prune: disabled` on the one object that must stay.
> - **Forgetting a suspended Flux `Kustomization`.** It looks healthy in `flux get` but applies nothing. Check the `SUSPENDED` column whenever a commit does not arrive.
> - **Removing a file but not its line in `kustomization.yaml`.** Kustomize then fails to build the folder, and the Flux `Kustomization` reports an error instead of pruning.
