# Environments In A Repository

Most applications run more than once: staging for tests, production for users. This part shows how to describe both from one repository, so that the two differ only where you want them to.

The commands below need the `GitRepository` `fleet` and the Flux `Kustomization` `namespaces`, which created the namespaces `staging` and `production`:

<!-- astrona:playground:renew -->

## Base and overlays

Kustomize lets you write a **base**, which is the common part, and **overlays**, which change a few values on top of it. The repository has this shape:

```text
apps/podinfo/
  base/                 Deployment, Service, no namespace
  overlays/
    staging/            1 replica, message "staging"
    production/         2 replicas, message "production"
infrastructure/
  namespaces/           the namespaces staging and production
```

An overlay lists the base as a resource and applies patches. Read the production overlay:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cat fleet/apps/podinfo/overlays/production/kustomization.yaml
kubectl kustomize fleet/apps/podinfo/overlays/production | head -40
```

`kubectl kustomize` builds the overlay on your machine, exactly as kustomize-controller does in the cluster. Use it before you push.

## One folder per environment, not one branch

There are two common ways to keep environments apart. One is a **branch per environment**: `staging` and `production` are branches, and changes are merged from one to the next. The other is a **folder per environment** on one branch.

This course uses folders. Differences between branches are hard to read, they grow over time, and a change can be merged in the wrong direction. With folders, `git diff` between two overlays shows the differences between environments in one view, and a single commit can change both.

## One Flux Kustomization per environment

Each environment gets its own Flux `Kustomization`, with its own path and its own target namespace:

```sh
flux create kustomization staging \
  --source=GitRepository/fleet --path=./apps/podinfo/overlays/staging \
  --target-namespace=staging --depends-on=namespaces \
  --prune=true --wait=true --interval=5m
flux create kustomization production \
  --source=GitRepository/fleet --path=./apps/podinfo/overlays/production \
  --target-namespace=production --depends-on=namespaces \
  --prune=true --wait=true --interval=5m
```

Three fields do the work:

- `spec.path` selects the overlay. A wrong path applies the wrong environment and still reports success.
- `spec.targetNamespace` sets the namespace of every namespaced object that the Flux `Kustomization` applies. The base has no namespace on purpose, so the overlay and this field decide where it lands.
- `spec.dependsOn` makes the environment wait until the Flux `Kustomization` `namespaces` is ready. Without it, the first apply could fail because the namespace does not exist yet.

## Check the two environments side by side

```sh
flux get kustomizations
kubectl get deployments -A | grep podinfo
kubectl -n staging get deployment podinfo \
  -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].env[0].value}{"\n"}'
kubectl -n production get deployment podinfo \
  -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].env[0].value}{"\n"}'
```

Staging shows `1 staging`, and production shows `2 production`.

## Try it

1. Build the staging overlay with `kubectl kustomize` and compare it to the production overlay with `diff`.
2. Suspend `namespaces`, delete the namespace `production`, create `production` again without `--depends-on` and read the `Ready` message. Then resume `namespaces`.
3. Change `targetNamespace` of `production` to `staging` with `kubectl -n flux-system patch`, reconcile, and look at both namespaces. Then undo it.

## Your mission: Separate Staging From Production

You can now describe two environments and give each its own Flux object. The graded lab gives you a `production` object that applies without an error but does not run production. Find out why, and fix it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-010-03
astrona start ats-094-playground-010-03
```
