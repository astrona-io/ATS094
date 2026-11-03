# Solution: Fix The Helm Release

Work the task yourself first. Running `astrona submit -c sections/section-020/module-04/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the `HelmRelease` `podinfo` is `Ready` and its values use `replicaCount`, the Deployment comes from a 6.x chart version and runs 2 ready replicas with the right message, and the release is managed by Flux.

## Step 1: Read the first error

```sh
flux get helmreleases
flux get sources helm
kubectl -n flux-system get helmrelease podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The `HelmRelease` is not ready, and the message says that the chart cannot be found or is not ready. The `HelmChart` object that source-controller creates for the release carries the detail:

```sh
kubectl -n flux-system get helmchart
kubectl -n flux-system get helmchart flux-system-podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The message says that no chart version matches the constraint `9.x`. The `HelmRepository` is fine: it lists versions of `podinfo`, but none of them starts with 9.

## Step 2: Fix the version

```sh
kubectl -n flux-system patch helmrelease podinfo --type=merge \
  -p '{"spec":{"chart":{"spec":{"version":"6.x"}}}}'
flux reconcile helmrelease podinfo --with-source
flux get helmreleases
```

The release installs. The `HelmRelease` is `Ready`, but this is not the end of the task.

## Step 3: Compare the result with the values

```sh
kubectl -n podinfo get deployment podinfo
kubectl -n flux-system get helmrelease podinfo -o jsonpath='{.spec.values}{"\n"}'
```

The Deployment runs 1 replica, although the values ask for 2. The values contain `replicas: 2`, and the chart reads `replicaCount`. Helm does not report an unknown key, so the install succeeds and the key has no effect. The message `hello from helm` works because `ui.message` is a key the chart does know.

## Step 4: Fix the values

A merge patch with `null` removes a key. Remove the wrong key and add the right one:

```sh
kubectl -n flux-system patch helmrelease podinfo --type=merge \
  -p '{"spec":{"values":{"replicas":null,"replicaCount":2}}}'
flux reconcile helmrelease podinfo --with-source
kubectl -n podinfo get deployment podinfo
```

A new upgrade of the release runs and the Deployment reaches 2 ready replicas.

## Step 5: Prove it

```sh
flux get helmreleases
kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.metadata.labels.helm\.sh/chart}{"\n"}{.status.readyReplicas}{"\n"}{.spec.template.spec.containers[0].env}{"\n"}'
```

The label names a 6.x chart, 2 replicas are ready, and the environment holds `PODINFO_UI_MESSAGE` with the message `hello from helm`.

## Why the wrong fixes fail

- Running `helm install` creates a release that Flux does not own, and the grader reads the `HelmRelease`.
- Changing only the version leaves 1 replica.
- Scaling the Deployment with `kubectl scale` gives 2 replicas for a moment, until the next upgrade or drift correction, and the values still use the wrong key.
