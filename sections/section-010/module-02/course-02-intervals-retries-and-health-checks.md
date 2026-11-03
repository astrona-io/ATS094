# Intervals, Retries And Health Checks

A controller cannot reconcile every object all the time, and it should not try a broken object a thousand times a minute. Flux solves this with three time settings and a health check. This part explains each setting, and how a Flux `Kustomization` decides that the objects it applied are healthy.

The commands below need the `GitRepository` `fleet` and the Flux `Kustomization` `infra`, both `Ready`. The `flux create source git` and `flux create kustomization` commands create them, with the path `./infrastructure` for `infra`:

<!-- astrona:playground:renew -->

## Three time settings

A Flux `Kustomization` has these time fields:

| Field | What it sets | Default |
| --- | --- | --- |
| `spec.interval` | How often the controller applies the folder again after a success | Required, no default |
| `spec.retryInterval` | How long the controller waits before it retries after a failure | The value of `interval` |
| `spec.timeout` | How long a single apply and health check may take | The value of `interval` |

`interval` also acts as drift correction. Even without a new commit, the controller builds and applies the folder every `interval`, so a manual change lives at most that long. The `GitRepository` has its own `interval`, which sets how often source-controller checks the branch for a new commit. A new commit starts a run of the Flux `Kustomization` at once, because it watches the source for a new revision.

Read the settings of `infra` and set a shorter retry:

```sh
kubectl -n flux-system get kustomization infra \
  -o jsonpath='interval={.spec.interval} retry={.spec.retryInterval} timeout={.spec.timeout}{"\n"}'
kubectl -n flux-system patch kustomization infra --type=merge -p '{"spec":{"retryInterval":"30s"}}'
```

The first command prints the interval of 5 minutes, and empty values for `retryInterval` and `timeout`: an empty value means the default. The second command sets the retry to 30 seconds. A short retry interval helps when a failure is likely to clear soon, for example while a dependency starts. A long `interval` keeps the load on the API server low.

## Why a failed run waits

Without `retryInterval`, a failed object would wait for a full `interval` before the next try. With a 1-hour interval, a typo fixed in Git a minute after a failure would take effect only after the retry. Flux avoids most of that wait: a new commit, or a change of the object, starts a run at once. `retryInterval` only matters when nothing changes and the failure comes from outside, such as an image that is still being pulled.

You can always skip the wait with a request:

```sh
flux reconcile kustomization infra --with-source
```

The command sets the annotation `reconcile.fluxcd.io/requestedAt` on the object. A controller reads that annotation as a request to run now, and writes the value it handled into `.status.lastHandledReconcileAt`. You can read both:

```sh
kubectl -n flux-system get kustomization infra \
  -o jsonpath='{.metadata.annotations.reconcile\.fluxcd\.io/requestedAt}{"\n"}{.status.lastHandledReconcileAt}{"\n"}'
```

When the two values are equal, the controller has handled your request.

## What healthy means: wait

Applying objects and the objects being healthy are two different events. The API server accepts a Deployment at once, but the pods need time to start. Without a health check, the Flux `Kustomization` is `Ready` as soon as the apply call succeeds. With `wait: true`, kustomize-controller checks every object it applied, and the Flux `Kustomization` becomes `Ready` only when all of them are healthy.

The controller decides health with the same rules as `kubectl rollout status`: a Deployment is healthy when its new replicas are available, a Job when it completed, and a `Namespace` when it is active. Objects of a kind without such a rule count as healthy when they exist. `timeout` limits the wait. When the time runs out, the run fails and the message names the object that was not healthy.

## What healthy means: healthChecks

`wait` checks everything in the folder. `healthChecks` checks only the objects you list, and it can also name objects that Flux did not apply, for example a controller installed by another Flux `Kustomization`:

```yaml
spec:
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: cache
      namespace: platform
```

Each entry needs `apiVersion`, `kind`, `name` and, for namespaced kinds, `namespace`. If the namespace is wrong, the object is simply not found and the run fails, which is the most common mistake. Add the check to `infra`, and watch the object:

```sh
kubectl -n flux-system patch kustomization infra --type=merge -p \
  '{"spec":{"timeout":"2m","healthChecks":[{"apiVersion":"apps/v1","kind":"Deployment","name":"cache","namespace":"platform"}]}}'
flux reconcile kustomization infra
flux get kustomizations
kubectl -n platform get deployment cache
```

`infra` becomes `Ready` once the Deployment `cache` has one available replica. Setting both `wait: true` and `healthChecks` does not check both: when `wait` is `true`, kustomize-controller checks all applied objects and ignores the `healthChecks` list. Choose one. Use `wait` when everything in the folder must be healthy, and `healthChecks` when a few named objects decide health.

## What a failed health check looks like

Break the check on purpose to see the failure. Point it at a Deployment that does not exist:

```sh
kubectl -n flux-system patch kustomization infra --type=merge -p \
  '{"spec":{"timeout":"30s","healthChecks":[{"apiVersion":"apps/v1","kind":"Deployment","name":"cache","namespace":"default"}]}}'
flux reconcile kustomization infra
flux events --for Kustomization/infra
```

The run applies the folder, waits up to 30 seconds, and then fails. The `Ready` condition becomes `False`, its message says the health check failed, and a `Warning` event names the Deployment that was not found. The objects that were applied stay in the cluster: a failed health check does not roll anything back. Put the correct namespace back before you go on:

```sh
kubectl -n flux-system patch kustomization infra --type=merge -p \
  '{"spec":{"healthChecks":[{"apiVersion":"apps/v1","kind":"Deployment","name":"cache","namespace":"platform"}]}}'
flux reconcile kustomization infra
```

You can now say how often each part runs, how it retries, and what makes an object healthy. The next question is order: how does one Flux `Kustomization` wait for another that must be healthy first?

## Common pitfalls

> [!WARNING]
> - **A very long `interval` without a short `retryInterval`.** A failure that clears by itself waits a long time for the next try.
> - **Setting `wait: true` and `healthChecks` together.** The list is ignored. Remove one of them.
> - **A health check in the wrong namespace.** The object is not found and the run fails, even though the Deployment is fine.
> - **A `timeout` shorter than the startup time of the pods.** The run fails before the pods can become ready. Allow for image pulls.
