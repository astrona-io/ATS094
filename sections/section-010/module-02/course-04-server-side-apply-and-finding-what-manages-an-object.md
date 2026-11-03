# Server-Side Apply And Finding What Manages An Object

Two different tools can change the same Deployment: Flux, and a person with `kubectl`. This part shows how Kubernetes tracks which one changed which field, what that means for drift correction, and how to find the Flux objects behind any live resource when you only know the resource.

The commands below need the Flux `Kustomization` objects `infra` (path `./infrastructure`) and `apps` (path `./apps/podinfo`), both `Ready`:

<!-- astrona:playground:renew -->

## Server-side apply and field managers

kustomize-controller applies objects with **server-side apply**. In a client-side `kubectl apply`, the tool compares files and sends a patch. In server-side apply, the tool sends the full desired object, and the API server merges it and records a **field manager** for each field: the name of the tool that last set it. kustomize-controller uses the field manager name `kustomize-controller`.

Show the managers of the Deployment `podinfo`:

```sh
kubectl -n podinfo get deployment podinfo --show-managed-fields -o yaml
```

Under `metadata.managedFields` there is an entry for `kustomize-controller`, with the operation `Apply`, and a list of the fields it owns, such as `spec.replicas`. Other entries belong to other managers, for example the Deployment controller of Kubernetes that owns the `status`.

## A manual change and ownership

Scale the Deployment by hand and look at the managers again:

```sh
kubectl -n podinfo scale deployment podinfo --replicas=4
kubectl -n podinfo get deployment podinfo --show-managed-fields -o yaml
```

The field `spec.replicas` now has a second claim from the command `kubectl`, with the operation `Update`. Two managers touched one field, and the API server records both. On the next run, kustomize-controller applies the value from Git and takes the field back, because its apply carries a value for it. The drift is corrected: the Deployment has the replicas of Git again.

Ownership matters for a field that Flux does **not** set. If a file in Git leaves `replicas` out, for example because a HorizontalPodAutoscaler sets it, kustomize-controller never claims that field. A manual or automatic change to it stays, and Flux does not report drift for it. Drift correction covers only the fields the manifest contains.

## When apply fails: force

Some changes cannot be made in place. The field `spec.selector` of a Deployment and the `spec.clusterIP` of a Service are **immutable**: the API server rejects a change. A Flux `Kustomization` that tries to change one fails with an error from the API server, and its message names the field.

Setting `spec.force: true` changes the behavior. When the apply fails because of an immutable field, kustomize-controller deletes the object and creates it again. The recreation interrupts the workload, and it removes the data of objects such as a PersistentVolumeClaim only if the claim itself is recreated. Use `force` for one change that needs it, and read the message before you turn it on.

```sh
kubectl -n flux-system patch kustomization apps --type=merge -p '{"spec":{"force":true}}'
kubectl -n flux-system get kustomization apps -o jsonpath='{.spec.force}{"\n"}'
kubectl -n flux-system patch kustomization apps --type=merge -p '{"spec":{"force":false}}'
```

The commands turn the field on, read it, and turn it off again. Leaving it on makes every future immutable-field change recreate the object without a warning.

## Find the Flux objects behind a resource

In a large cluster, you often start from a resource, not from a Flux object. Flux writes the labels `kustomize.toolkit.fluxcd.io/name` and `kustomize.toolkit.fluxcd.io/namespace` on every object a Flux `Kustomization` applies, and the command `flux trace` reads them and follows the chain back to Git:

```sh
flux trace deployment podinfo --namespace podinfo
```

The output lists the object, the Flux `Kustomization` that applied it with its path and its last applied revision, and the `GitRepository` with its URL and branch. When the resource has no Flux labels, the command says that the object is not managed by Flux. That answer is useful too: it tells you the object was created by hand.

The opposite question is which objects a Flux `Kustomization` owns. `flux tree` reads the inventory and prints them:

```sh
flux tree kustomization apps
```

The tree shows the namespace, the Deployment and the Service from `apps/podinfo`. A `flux tree` of the `infra` object shows the other folder. The same list is in `.status.inventory`, and it is the list that prune uses.

## Tracing after a failure

Use the two commands together when something is wrong. Start from a symptom, such as a Deployment with 4 replicas instead of 2:

```sh
flux trace deployment podinfo --namespace podinfo
flux get kustomizations
flux events --for Kustomization/apps
```

The trace tells you which object should own the Deployment and which revision it should match. `flux get` tells you whether that object is ready or suspended. The events tell you what it did last. In most cases, one of the three explains the difference.

You have now followed one change through the whole chain: Git commit, artifact, build, server-side apply, field ownership, health check and status. The module summary puts the parts together.

## Common pitfalls

> [!WARNING]
> - **Leaving `force: true` on.** Every immutable-field error then deletes and recreates the object, without a warning.
> - **Expecting Flux to revert a field it does not set.** Flux corrects only fields that are in the manifest.
> - **Running `flux trace` on a resource that was created by hand.** The result says it is not managed by Flux. That is the answer, not an error.
> - **Reading `managedFields` without `--show-managed-fields`.** `kubectl get -o yaml` hides them by default.
