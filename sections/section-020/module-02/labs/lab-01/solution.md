# Solution: Pin The GitRepository To The Reviewed Release

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the `GitRepository` `fleet` uses the Secret `fleet-auth` and holds an artifact of the tag `release-1`, the Flux `Kustomization` `podinfo` is `Ready` on that revision, and the cluster runs `podinfo` but not `unreviewed`.

## Step 1: Read the source status

The chain starts at the source:

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The message says that source-controller could not read the authentication Secret `fleet-credentials`: it was not found. Confirm which Secrets exist:

```sh
kubectl -n flux-system get secret
```

The Secret is called `fleet-auth`. A `secretRef` names a Secret in the same namespace as the `GitRepository`, and a wrong name stops the clone before it starts.

## Step 2: Fix the Secret name

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"secretRef":{"name":"fleet-auth"}}}'
flux reconcile source git fleet
flux get sources git
```

The source becomes `Ready` on a revision `main@sha1:` followed by a hash. That revision includes the unreviewed commit, so the task is not finished: when the Flux `Kustomization` applies it, the Deployment `unreviewed` appears. The next step removes it again, because pruning deletes objects that are no longer in the revision.

## Step 3: Pin the source to the tag

A branch moves with every push. A tag names one commit. Change the reference from the branch to the tag:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"branch":null,"tag":"release-1"}}}'
flux reconcile source git fleet
flux get sources git
```

The patch sets `branch` to `null`, which removes the field in a merge patch, and sets `tag`. The revision is now `release-1@sha1:` followed by the commit hash of the tagged commit.

## Step 4: Let the sync follow

```sh
flux reconcile kustomization podinfo
flux get kustomizations
kubectl -n podinfo get deployments
```

`podinfo` is `Ready` on the revision of the tag. The Deployment `podinfo` runs 2 replicas. If `unreviewed` was applied between step 2 and step 3, it is gone now: with `prune: true`, kustomize-controller deletes objects that are in its inventory and not in the new revision.

## Why the wrong fixes fail

- Applying the Deployment files with `kubectl` leaves the Flux objects broken, and the grader checks the Flux label.
- Fixing only the Secret name leaves the source on `main`. The revision is `main@sha1:`, and the grader requires `release-1@sha1:`.
- Leaving both `branch` and `tag` set is unclear: when several references are set, Flux uses the most specific one, and the `ref` should say plainly what you mean. Remove `branch`.
- Deleting the extra commit or the tag changes the repository, which the task forbids.
