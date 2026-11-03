# Solution: Uninstall Flux And Keep The Workload

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: Flux and its definitions are gone, the Deployment is the one that ran at the start, and the namespace `flux-system` with its ConfigMap remains.

## Step 1: See what you would remove

```sh
flux get kustomizations
kubectl get crd | grep fluxcd.io
kubectl -n flux-system get deployments
```

Flux has six controllers and a set of definitions. The Flux `Kustomization` `podinfo` owns the application and has pruning on.

## Step 2: Do not delete the Flux Kustomization

```sh
flux delete kustomization podinfo
```

Do not run this. A Flux `Kustomization` with pruning on removes everything it applied when it is deleted. The Deployment would be deleted and the grader would see a new identity if it were recreated.

## Step 3: Preview the uninstall

```sh
flux uninstall --keep-namespace --dry-run
```

The dry run lists what would be deleted without removing it. Without `--keep-namespace`, the namespace `flux-system` is deleted too, and the ConfigMap `team-notes` goes with it.

## Step 4: Uninstall

```sh
flux uninstall --keep-namespace --silent
```

`--silent` skips the confirmation question. The command first removes the finalizers from the Flux objects, so the applied objects are not garbage collected, then deletes the controllers and the definitions.

## Step 5: Prove it

```sh
kubectl get crd | grep fluxcd.io
kubectl -n flux-system get deployments
kubectl -n podinfo get deployment podinfo
kubectl -n flux-system get configmap team-notes
```

The first two return nothing. The Deployment still has 2 ready replicas, and the ConfigMap exists.

## Why the wrong fixes fail

- Deleting the Flux `Kustomization` first removes the application.
- `flux uninstall` without `--keep-namespace` removes the namespace and the ConfigMap `team-notes`.
- Deleting the definitions with `kubectl delete crd` removes all Flux objects with their finalizers still set, which can block the deletion and leave the objects stuck.
