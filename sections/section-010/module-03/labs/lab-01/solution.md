# Solution: Separate Staging From Production

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: all three Flux `Kustomization` objects are `Ready`, production runs its own configuration in its own namespace, and staging is unchanged.

## Step 1: Compare what each environment applies

```sh
flux get kustomizations
kubectl -n flux-system get kustomization staging production \
  -o custom-columns=NAME:.metadata.name,PATH:.spec.path,TARGET:.spec.targetNamespace
```

Both objects are ready. They have the same path, `./apps/podinfo/overlays/staging`, and the same target namespace, `staging`. Production applies the staging overlay into the staging namespace. Because both objects apply the same manifests to the same objects, the production object shows as ready without doing anything of its own.

Prove it from the cluster:

```sh
kubectl get deployments -A | grep podinfo
```

Only the namespace `staging` has a Deployment.

## Step 2: Fix the path

```sh
kubectl -n flux-system patch kustomization production --type=merge \
  -p '{"spec":{"path":"./apps/podinfo/overlays/production"}}'
flux reconcile kustomization production --with-source
```

The overlay is now the right one, but `targetNamespace` still moves every object into `staging`. Two Flux `Kustomization` objects now claim a Deployment with the same name in the same namespace, and the namespace `production` still has no Deployment. Check:

```sh
kubectl get deployments -A | grep podinfo
```

## Step 3: Fix the target namespace

```sh
kubectl -n flux-system patch kustomization production --type=merge \
  -p '{"spec":{"targetNamespace":"production"}}'
flux reconcile kustomization production --with-source
flux get kustomizations
```

All three objects are `Ready`.

## Step 4: Prove it

```sh
kubectl -n production get deployment podinfo \
  -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].env[0].value}{"\n"}'
kubectl -n staging get deployment podinfo \
  -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].env[0].value}{"\n"}'
```

Production prints `2 production`, and staging prints `1 staging`.

## Why the wrong fixes fail

- Editing the Deployment in the namespace `production` with `kubectl` is reverted by Flux, and the object that Flux applies is still the wrong one.
- Changing only the path leaves the objects in the namespace `staging`.
- Changing only `targetNamespace` creates a Deployment with the staging values in the namespace `production`.
