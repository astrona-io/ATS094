# Flux Events And notification-controller

Every Flux controller records what it does. Before you send those records anywhere, you should know how to read them yourself. This part shows the events, and the path that an event takes to notification-controller.

The commands below need a `GitRepository` named `fleet` and a Flux `Kustomization` named `podinfo` in the namespace `flux-system`:

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

## Two kinds of events

A Flux controller creates a Kubernetes event whenever something changes in an object it owns, for example a new revision applied or a reconcile that failed. These events are stored in the cluster and disappear after about an hour. Read them with:

```sh
flux events --for Kustomization/podinfo
kubectl -n flux-system events --for kustomization/podinfo
```

Each event has a type (`Normal` or `Warning`), a reason (such as `ReconciliationSucceeded` or `ReconciliationFailed`), a message and the object it is about. The messages of the Flux `Kustomization` include the revision and a list of what changed.

The controllers also send the same event over HTTP to notification-controller. This is the second kind. It is the same information in a form that can be forwarded. In notifications, an event has the severity `info` for normal events and `error` for failures.

## The path of an event

1. A controller, such as kustomize-controller, finishes a reconcile and records the event.
2. The controller posts the event to the service `notification-controller` in `flux-system`.
3. notification-controller looks at every `Alert` and checks if the event is from one of its `eventSources`, and if the severity matches.
4. For each matching `Alert`, it sends a message to the `Provider` named in `providerRef`.

If step 3 finds no match, the event is dropped without a message. This is why a wrong namespace or a wrong severity is silent: nothing fails, and nothing arrives. Look at the log of the controller when you debug:

```sh
flux logs --kind=Alert --level=info
kubectl -n flux-system logs deploy/notification-controller --tail=20
```

## Kinds that can be event sources

An `Alert` can use events from any Flux kind: `GitRepository`, `OCIRepository`, `HelmRepository`, `Bucket`, `HelmChart`, `Kustomization`, `HelmRelease`, `ImageRepository`, `ImagePolicy`, `ImageUpdateAutomation`, and also `Receiver`. A source with the name `*` matches every object of that kind. You can also select by labels with `matchLabels`.

## Try it

1. Create the `GitRepository` and the Flux `Kustomization`, and run `flux events --for Kustomization/podinfo`. What reason does the newest event have?
2. Suspend the `GitRepository`, push nothing, and resume it. Which events are created?
3. Break the path of the Flux `Kustomization` and read the `Warning` events. Fix the path again.
