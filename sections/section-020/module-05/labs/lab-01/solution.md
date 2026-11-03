# Solution: Route The Flux Events

Work the task yourself first. Running `astrona submit -c sections/section-020/module-05/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the `Alert` is `Ready` and refers to the `Provider` `team-webhook`, its event sources are the two objects in `flux-system`, and its severity is `info`.

## Step 1: Read the state of both objects

```sh
kubectl -n flux-system get providers.notification.toolkit.fluxcd.io,alerts.notification.toolkit.fluxcd.io
kubectl -n flux-system get alerts.notification.toolkit.fluxcd.io app-events \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The `Provider` is ready and the `Alert` is not. The message says that the provider `team-hook` cannot be found. The name in `spec.providerRef` has to be the name of a `Provider` in the same namespace:

```sh
kubectl -n flux-system get providers.notification.toolkit.fluxcd.io
```

The only `Provider` is `team-webhook`.

## Step 2: Read the rest of the spec

A ready `Alert` is not yet a correct one. Print the rest of the spec:

```sh
kubectl -n flux-system get alerts.notification.toolkit.fluxcd.io app-events -o jsonpath='{.spec}{"\n"}'
```

Two more problems are visible. Both event sources name the namespace `default`, but the objects are in `flux-system`, so the `Alert` would never match an event. And `eventSeverity` is `error`, so a successful reconcile sends nothing.

## Step 3: Fix all three

```sh
kubectl -n flux-system patch alerts.notification.toolkit.fluxcd.io app-events --type=merge -p '{
  "spec": {
    "providerRef": {"name": "team-webhook"},
    "eventSeverity": "info",
    "eventSources": [
      {"kind": "Kustomization", "name": "podinfo", "namespace": "flux-system"},
      {"kind": "GitRepository", "name": "fleet", "namespace": "flux-system"}
    ]
  }
}'
```

A merge patch replaces the list `eventSources` as a whole, which is what you want here.

## Step 4: Prove it

```sh
kubectl -n flux-system get alerts.notification.toolkit.fluxcd.io app-events \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}{.spec.eventSeverity}{"\n"}{.spec.providerRef.name}{"\n"}'
flux events --for Kustomization/podinfo
```

The `Alert` is `True`, the severity is `info` and the provider is `team-webhook`. The command `flux events` lists the events that the Alert will match.

## Why the wrong fixes fail

- Creating a second Provider named `team-hook` makes the `Alert` ready, but the task keeps the existing Provider and forbids new ones.
- Removing `namespace` from the event sources would select objects in the namespace of the `Alert`, but the grader requires the namespace to be written out, which is also clearer to the next reader.
- Leaving `eventSeverity: error` fails the third check.
