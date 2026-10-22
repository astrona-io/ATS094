# Solution: Make Flux Apply The Application From Git

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the `GitRepository` `fleet` is `Ready` on the branch `main`, the Flux `Kustomization` `podinfo` is `Ready` and applies `./apps/podinfo` with `prune: true`, and Flux (not `kubectl`) applied the `podinfo` Deployment, which runs 2 ready replicas.

## Step 1: Check the source first

The chain starts at the source, so look there first:

```sh
flux get sources git
```

The `fleet` row shows `READY` as `False`. The message says that source-controller could not find the remote reference `refs/heads/master`. The `GitRepository` follows the branch `master`, and the repository has only `main`. Confirm the branch the object asks for:

```sh
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.ref.branch}{"\n"}'
```

It prints `master`. Without a usable source, the Flux `Kustomization` has nothing to apply, so fix this before anything else.

## Step 2: Fix the branch

Change the branch to `main`. `kubectl patch` changes only the field you name:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux reconcile source git fleet
flux get sources git
```

`fleet` is now `Ready`, with a revision of the form `main@sha1:` followed by the commit hash. You could also edit the object with `kubectl edit` or apply a corrected file; the result is the same.

## Step 3: Check the sync

The source is fixed, but `podinfo` is still missing. Look at the Flux `Kustomization` and its events:

```sh
flux get kustomizations
flux events --for Kustomization/podinfo
```

`podinfo` is still not ready. The message says that kustomize-controller cannot find the path `app/podinfo` in the artifact. The repository folder is `apps/podinfo`, with an `s`.

## Step 4: Fix the path

Change the path and ask kustomize-controller to apply it now:

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge -p '{"spec":{"path":"./apps/podinfo"}}'
flux reconcile kustomization podinfo
```

`flux reconcile` waits until the controller has finished. Because the Flux `Kustomization` has `wait: true`, it reports success only after the `podinfo` pods are ready.

## Step 5: Prove the fix

Check both objects and the application:

```sh
flux get sources git
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

Both objects are `Ready` on the same `main@sha1:` revision, and the Deployment shows `2/2` ready. To see that Flux applied the Deployment, list the inventory of the Flux `Kustomization`:

```sh
kubectl -n flux-system get kustomization podinfo -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
```

The list has `podinfo_podinfo_apps_Deployment` and `podinfo_podinfo__Service`. Those entries exist only for objects that kustomize-controller applied.

## Step 6: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `kubectl apply -k apps/podinfo` from a clone | `podinfo` runs, but the Flux objects are still broken. Nothing is in the inventory, and the next change in Git never arrives |
| Create a branch `master` in Gitea | The source becomes ready, but you changed the repository to hide a wrong object, and two branches now claim to be the truth |
| Create a second `GitRepository` with the right branch | Two sources for one repository, and the broken one stays |
| Suspend the Flux `Kustomization` | The errors stop, and so does all reconciliation |

## Common mistakes

- Fixing the path first. The Flux `Kustomization` cannot become ready while the source has no artifact, so the path fix looks like it did nothing.
- Reading only `kubectl get`. The reason for a failure is in the message of `flux get` and in `flux events`.
- Waiting for the interval. `flux reconcile` makes the controllers run now.

## Practice on your own

- Remove `ref` from the `GitRepository` and predict which branch source-controller tries.
- Set the path to `./apps` and explain the error you get.
- Change `interval` on the `GitRepository` to `10m`, push a commit, and compare how long it takes with and without `flux reconcile source git fleet`.
