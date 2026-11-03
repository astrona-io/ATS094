# Solution: Fix The Variable Substitution

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the Flux `Kustomization` `podinfo` is `Ready` and reads its variables from the ConfigMap `cluster-vars`, the Deployment `podinfo` runs in the namespace `podinfo` with the message from the ConfigMap, and no Deployment `podinfo` exists in another namespace.

## Step 1: Read the first error

```sh
flux get kustomizations
kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The message says the variable source `Secret/cluster-vars` was not found. The Flux `Kustomization` reads its variables from a Secret with that name, and the variables are in a ConfigMap. The `kind` in `substituteFrom` must match the kind of the object that holds the variables:

```sh
kubectl -n flux-system get configmap cluster-vars -o jsonpath='{.data}{"\n"}'
kubectl -n flux-system get secret cluster-vars
```

The first command prints `ui_message`. The second reports that the Secret does not exist.

## Step 2: Fix the kind

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge \
  -p '{"spec":{"postBuild":{"substituteFrom":[{"kind":"ConfigMap","name":"cluster-vars"}]}}}'
flux reconcile kustomization podinfo --with-source
kubectl -n flux-system get kustomization podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The first error is gone, and the run goes further: it builds the folder and tries to apply it. Now the message reports a second problem, a namespace that does not exist.

## Step 3: Find the namespace problem

Read the object and look at the namespace setting:

```sh
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.targetNamespace}{"\n"}'
```

It prints `staging`. `targetNamespace` sets the namespace of every namespaced object in the build. The Deployment and the Service are moved into `staging`, which does not exist, so the apply fails. The Namespace object `podinfo` from the repository is still created, but nothing runs in it. Do not create the namespace `staging`: the application belongs in `podinfo`, and the grader checks that no Deployment exists anywhere else.

## Step 4: Remove the setting

The manifests in Git already name the namespace `podinfo`, so the field is not needed. Remove it with a merge patch:

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge \
  -p '{"spec":{"targetNamespace":null}}'
flux reconcile kustomization podinfo --with-source
flux get kustomizations
```

Setting `targetNamespace` to `podinfo` would also pass. The object is `Ready`.

## Step 5: Prove it

```sh
kubectl -n flux-system get configmap cluster-vars -o jsonpath='{.data.ui_message}{"\n"}'
kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].env[0].value}{"\n"}{.status.readyReplicas}{"\n"}'
kubectl get deployments -A | grep podinfo
```

The environment value in the Deployment equals the value in the ConfigMap, 2 replicas are ready, and the Deployment appears only in the namespace `podinfo`.

## Why the wrong fixes fail

- Writing the message into `postBuild.substitute` as a literal passes the message check but removes the ConfigMap source, and the grader requires it.
- Creating the namespace `staging` makes the object ready, but the Deployment runs in the wrong place.
- Applying the files with `kubectl` leaves the Flux object broken and the Flux label missing.
