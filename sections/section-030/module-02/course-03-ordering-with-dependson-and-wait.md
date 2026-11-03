# Ordering With dependsOn And wait

Flux applies each Flux `Kustomization` independently. Without help, all of them start at the same time, in no fixed order. This part adds the order that the layout needs.

The commands below need the `GitRepository` `fleet` and the three folders of the repository:

<!-- astrona:playground:renew -->

## dependsOn

`spec.dependsOn` lists Flux `Kustomization` objects that must be ready before this one is applied. The list uses names, and the namespace is the same unless you give one:

```sh
flux create kustomization infrastructure-controllers \
  --source=GitRepository/fleet --path=./infrastructure/controllers \
  --prune=true --wait=true --interval=5m
flux create kustomization infrastructure-configs \
  --source=GitRepository/fleet --path=./infrastructure/configs \
  --depends-on=infrastructure-controllers \
  --prune=true --wait=true --interval=5m
flux create kustomization apps \
  --source=GitRepository/fleet --path=./apps/kind \
  --depends-on=infrastructure-configs \
  --prune=true --wait=true --interval=5m
flux get kustomizations
```

If a dependency is not ready, the Flux `Kustomization` stays not ready, and its message names the dependency. It does not fail and it does not apply anything. When the dependency becomes ready, the next reconcile goes ahead.

## wait and health checks

`dependsOn` checks the **Ready condition** of the other object. That condition becomes true when the apply worked. It does not mean that the applied things work, unless you ask for it:

- `spec.wait: true` makes the Flux `Kustomization` wait until every object it applied is ready. For a custom resource definition that means established. For a Deployment it means the rollout is complete.
- `spec.healthChecks` lists specific objects to wait for instead. Use it when only some objects matter.
- `spec.timeout` is how long the wait lasts before the object is reported as failed.

For the controllers folder this matters: with `wait: true` the object becomes ready only after the definition is established, so the Flux `Kustomization` for the configuration never starts too early.

## A dependency chain

```sh
flux tree kustomization apps
kubectl -n flux-system get kustomization -o custom-columns=NAME:.metadata.name,DEPENDS:.spec.dependsOn[*].name
```

Keep chains short. A long chain means the last object waits for all the others, and one failure at the start stops everything behind it. Dependencies between unrelated applications are a sign that something should move into `infrastructure`.

Two limits to know:

- `dependsOn` works between objects in the same cluster only.
- A dependency that never becomes ready blocks the objects behind it for good. Find the first object in the chain that is not ready and start there.

## Find the first failure

When three objects are not ready, do not start with the last one. Read them in the order of the dependencies:

```sh
flux get kustomizations
kubectl -n flux-system get kustomization infrastructure-controllers \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The message of the first object names the real cause, such as a source that does not exist, a wrong path, or a failed health check.

## Try it

1. Create the three objects above and run `flux get kustomizations` right away. Which objects wait?
2. Suspend `infrastructure-controllers`, reconcile `apps`, and read the message. Resume.
3. Set `spec.wait` to `false` on `infrastructure-controllers` and explain what could go wrong on a new cluster.

## Your mission: Wire Up The Cluster Entry Points

You can now describe the order of a cluster and build it with Flux objects. The graded lab gives you three objects where the controllers, the configuration and the application do not do their jobs. Find out why, and fix them.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-030-02
astrona start ats-094-playground-030-02
```
