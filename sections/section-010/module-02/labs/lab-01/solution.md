# Solution: Fix The Apps Kustomization That Waits Forever

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `infra` is `Ready` with a health check on the Deployment `cache` in the namespace `platform`, `apps` is `Ready` and depends on `infra`, both Deployments run their ready replicas, and Flux applied them.

## Step 1: Read both objects

Start with an overview and then read the status of each object:

```sh
flux get kustomizations
```

`infra` shows `READY` as `False`. `apps` shows `READY` as `False` as well, and its message names a dependency. Read the first one in full:

```sh
kubectl -n flux-system get kustomization infra -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
flux events --for Kustomization/infra
```

The message says the health check failed: the Deployment `cache` was not found in the namespace `default`. kustomize-controller applied the folder (the Deployment exists in the namespace `platform`), then waited for a Deployment that does not exist where the health check looks.

## Step 2: Fix the health check

The health check must point at the namespace where the Deployment runs. Confirm where it runs, then patch the object:

```sh
kubectl get deployment -A | grep cache
kubectl -n flux-system patch kustomization infra --type=merge \
  -p '{"spec":{"healthChecks":[{"apiVersion":"apps/v1","kind":"Deployment","name":"cache","namespace":"platform"}]}}'
flux reconcile kustomization infra --with-source
flux get kustomizations
```

`infra` is now `Ready`. Removing the health check would also turn it green, but the object would then no longer prove that the cache runs, and the grader rejects that fix.

## Step 3: Read why apps waits

`apps` is still not applied. Read its message:

```sh
kubectl -n flux-system get kustomization apps -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The message says the dependency `flux-system/infrastructure` was not found. The field `spec.dependsOn` names a Flux `Kustomization` by name, and that object is called `infra`. Because the dependency can never be found, kustomize-controller does not even build the `apps` folder.

## Step 4: Fix the dependency

Point `dependsOn` at the real name and reconcile:

```sh
kubectl -n flux-system patch kustomization apps --type=merge \
  -p '{"spec":{"dependsOn":[{"name":"infra"}]}}'
flux reconcile kustomization apps
flux get kustomizations
```

Both objects are `Ready`. A `merge` patch replaces the whole `dependsOn` list, which is what you want here.

## Step 5: Prove it

```sh
kubectl -n platform get deployment cache
kubectl -n podinfo get deployment podinfo
kubectl -n podinfo get deployment podinfo -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}{"\n"}'
```

The Deployment `cache` has 1 ready replica and `podinfo` has 2. The label on `podinfo` is `apps`: Flux applied it.

## Why the wrong fixes fail

- Applying the files with `kubectl` creates the objects without the Flux label, so the grader sees that Flux did not apply them.
- Removing `dependsOn` or the health check makes the objects green but removes the ordering the task asks you to keep.
- Creating an empty Flux `Kustomization` called `infrastructure` satisfies the name but leaves the real `infra` broken, and the grader checks that `apps` depends on `infra`.
