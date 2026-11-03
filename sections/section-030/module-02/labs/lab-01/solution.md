# Solution: Wire Up The Cluster Entry Points

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: all three Flux `Kustomization` objects are `Ready`, each one refers to the right source, path and dependency, and the `Widget` and the application exist where the repository says.

## Step 1: Read what each object reports

```sh
flux get kustomizations
kubectl -n flux-system get kustomization -o custom-columns=NAME:.metadata.name,PATH:.spec.path,SOURCE:.spec.sourceRef.name,DEPENDS:.spec.dependsOn[*].name
```

`infrastructure-controllers` is not ready. Read its message:

```sh
kubectl -n flux-system get kustomization infrastructure-controllers \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

It names a `GitRepository` called `fleet-repo`. List the sources with `flux get sources git`. Only `fleet` exists.

## Step 2: Fix the source of the controllers

```sh
kubectl -n flux-system patch kustomization infrastructure-controllers --type=merge \
  -p '{"spec":{"sourceRef":{"name":"fleet"}}}'
flux reconcile kustomization infrastructure-controllers --with-source
```

## Step 3: Make the configuration wait for the controllers

The `Widget` needs the definition that the controllers folder creates. On a new cluster, `infrastructure-configs` would fail because the kind `Widget` is not known yet. Add the dependency:

```sh
kubectl -n flux-system patch kustomization infrastructure-configs --type=merge \
  -p '{"spec":{"dependsOn":[{"name":"infrastructure-controllers"}]}}'
flux reconcile kustomization infrastructure-configs
```

## Step 4: Point the application at the overlay

`apps` applies `./apps/base/podinfo`, which has no namespace and runs 1 replica. The overlay for this cluster is `./apps/kind`:

```sh
kubectl -n flux-system patch kustomization apps --type=merge \
  -p '{"spec":{"path":"./apps/kind"}}'
flux reconcile kustomization apps
flux get kustomizations
```

All three objects are `Ready`.

## Step 5: Prove it

```sh
kubectl -n infra get widget main
kubectl -n apps get deployment podinfo
```

The `Widget` exists and the Deployment has 2 ready replicas in the namespace `apps`.

## Why the wrong fixes fail

- Applying the `Widget` or the Deployment with `kubectl` is not the work of Flux, and the ownership labels would be missing.
- Creating a `GitRepository` called `fleet-repo` hides the wrong name and breaks the rule that you do not create objects.
- Fixing only the path of `apps` leaves the controllers unapplied, so the order is still wrong on a new cluster.
