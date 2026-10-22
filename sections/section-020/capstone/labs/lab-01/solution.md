# Solution: Find The Controller That Stopped Working

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: `kustomize-controller` is running, the `GitRepository` `fleet` is `Ready` with an artifact of `main`, the Flux `Kustomization` `podinfo` is `Ready` with the current revision, `podinfo` runs two ready replicas applied by Flux, and both Flux objects are the original ones.

## Step 1: Check the installation as a whole

Start with the cheapest question: are all the controllers running?

```sh
flux check
kubectl -n flux-system get deployments
```

`flux check` reports a problem with `kustomize-controller` and does not end with "all checks passed". The Deployment list shows why: `kustomize-controller` has `0/0` replicas, so it was scaled down, not crashing. While it is stopped, no Flux `Kustomization` is ever applied, whatever happens in Git.

## Step 2: Read the state of every Flux object

```sh
flux get all --all-namespaces
```

The `GitRepository` `fleet` shows `Ready False`, with a message that the Git operation failed because the repository was not found. The Flux `Kustomization` `podinfo` shows no recent change at all, because its controller is not running. So there is a second fault, and this one belongs to source-controller.

## Step 3: Find the source fault

Read the events and the URL of the `GitRepository`:

```sh
flux events --for GitRepository/fleet
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.url}{"\n"}'
```

The events repeat the clone failure, and the URL ends in `gitops/fleat.git`. The repository is called `fleet`. source-controller is healthy; it is doing exactly what the object asks, and the object asks for a repository that does not exist. If you want the full error, `flux logs --kind=GitRepository --name=fleet --level=error` shows source-controller's log lines for this one object.

## Step 4: Start kustomize-controller again

```sh
kubectl -n flux-system scale deployment kustomize-controller --replicas=1
kubectl -n flux-system rollout status deployment/kustomize-controller
```

The rollout finishes when the pod is ready. Running `flux install` again would also bring it back, but scaling is the smallest change that undoes the fault.

## Step 5: Fix the URL on the existing GitRepository

Change only the URL, so the object keeps its identity:

```sh
kubectl -n flux-system patch gitrepository fleet --type merge \
  -p '{"spec":{"url":"http://gitea.localtest.me:3000/gitops/fleet.git"}}'
```

`flux create source git fleet --url=http://gitea.localtest.me:3000/gitops/fleet.git --branch=main --secret-ref=fleet-auth` does the same: it updates the existing object instead of creating a new one. Do not delete the object and apply a new one; the grader rejects that.

## Step 6: Reconcile and prove it

Ask both controllers to run now instead of waiting a minute:

```sh
flux reconcile kustomization podinfo --with-source
flux get all --all-namespaces
kubectl -n podinfo get deployment podinfo --show-labels
```

`flux reconcile` waits until source-controller has a new artifact and kustomize-controller has applied it, then prints the revision. `flux get` shows both objects `Ready True` with the same `main@sha1:...` revision. The Deployment `podinfo` has `2/2` ready replicas and the label `kustomize.toolkit.fluxcd.io/name=podinfo`, which proves Flux applied it.

## Step 7: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the `GitRepository` and apply a new one | The grader sees a new object and fails the identity check |
| Create a repository called `fleat` in Gitea | The URL stays wrong; the grader requires `gitops/fleet.git` |
| `kubectl apply -k apps/podinfo` from a clone | `podinfo` runs, but without Flux's labels, and the Flux `Kustomization` is still not `Ready` |
| Fix only the URL | source-controller produces an artifact, but nobody applies it while `kustomize-controller` is stopped |

## Common mistakes

- Stopping after the first fault. The task says there are two.
- Blaming source-controller for the wrong URL. It reports the failure; the object holds the mistake.
- Waiting for the next interval instead of running `flux reconcile ... --with-source`.

## Practice on your own

- Scale `source-controller` to zero, push a change to Git, and predict what `flux get` shows for the `GitRepository` and for the Flux `Kustomization`.
- Suspend the Flux `Kustomization`, change the replica count in Git, and compare `status.artifact.revision` with `status.lastAppliedRevision`.
