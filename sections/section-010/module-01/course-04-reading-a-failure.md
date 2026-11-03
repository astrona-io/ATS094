# Reading A Failure

Flux reports every problem in the status of the object that has it. A fixed routine finds the cause faster than guessing. This part gives the routine and then breaks four things on purpose, so you see what each break looks like.

The commands below need a `GitRepository` named `fleet` and a Flux `Kustomization` named `podinfo` in the namespace `flux-system`, as created in the earlier parts:

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

## The routine

Work from the source toward the cluster. Each step answers one question, and the first step that fails holds the cause.

1. **Is the source ready?** `flux get sources git`. If not, the Flux `Kustomization` has nothing new to apply. Read the message of the `GitRepository`.
2. **Is the Flux `Kustomization` ready?** `flux get kustomizations`. Read its message. It names the first object that failed, or the dependency it waits for.
3. **Is it suspended?** The `SUSPENDED` column. A suspended object applies nothing and reports its last state.
4. **Which revision did each side get?** Compare `status.lastAppliedRevision` with `status.lastAttemptedRevision`. If they differ, the newest attempt failed.
5. **What do the events and logs say?** `flux events --for Kustomization/podinfo` and `flux logs --kind=Kustomization --name=podinfo --level=error`.
6. **What does the cluster say?** `kubectl -n podinfo get deployment,pods` and `kubectl -n podinfo describe pod`. A Flux `Kustomization` can be applied and the pods still fail to start.

```sh
kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{.status.lastAppliedRevision}{"\n"}{.status.lastAttemptedRevision}{"\n"}'
```

## Four breaks to try

Make one change, read the status, and undo it before the next. The commands patch the objects in the cluster, so Git stays untouched.

**A branch that does not exist.**

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"branch":"release"}}}'
flux get sources git
```

The `GitRepository` is not ready, and the message says the branch cannot be found. The Flux `Kustomization` stays ready because it keeps the last artifact that it applied. A broken source is easy to miss for this reason, so always read both. Undo it:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"branch":"main"}}}'
```

**A path that does not exist.**

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge \
  -p '{"spec":{"path":"./apps/missing"}}'
flux reconcile kustomization podinfo
flux get kustomizations
```

The Flux `Kustomization` is not ready, and the message says the path was not found in the artifact. The source is fine. Undo it with the path `./apps/podinfo`.

**A wrong credential.**

```sh
kubectl -n flux-system create secret generic fleet-auth-bad \
  --from-literal=username=gitops --from-literal=password=wrong
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"secretRef":{"name":"fleet-auth-bad"}}}'
flux get sources git
```

The `GitRepository` reports an authentication failure. Again the Flux `Kustomization` stays ready. Undo it with the Secret `fleet-auth`.

**A suspended object.**

```sh
flux suspend kustomization podinfo
flux get kustomizations
flux resume kustomization podinfo
```

The `SUSPENDED` column shows `True`. Everything else looks fine, which is why a forgotten suspend can hide for days.

## What a message tells you

- A message that names the source or the artifact points at fetching: branch, credential, address, network.
- A message that names a path or a file points at what is in the repository.
- A message that names an object and a field points at a manifest the cluster refused. Run `kubectl apply --dry-run=server -f <file>` on your machine to see the same error.
- A message that names a dependency or a health check points at timing or at an application that does not become ready.

## Try it

1. Run the four breaks and write down, for each one, which object is not ready and which stays ready.
2. Break the path and the branch at the same time. Which message do you fix first, and why?
3. Suspend the `GitRepository`, push a commit, and compare the revisions of the two objects. Resume it.
