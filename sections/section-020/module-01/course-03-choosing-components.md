# Choosing Components

A teammate wants Flux to watch a container registry for new image tags. They apply an `ImageRepository` object, and `kubectl` refuses it. Nothing is broken: Flux simply does not install every controller by default. This part shows which controllers Flux calls components, which ones you get without asking, how to add the rest, and how to check the result.

## Default and optional components

Flux calls each controller it can install a **component**. `flux install` and `flux bootstrap` install four components unless you say otherwise. The others are optional, because many clusters never need them:

| Component | Installed by default | What it is for |
| --- | --- | --- |
| `source-controller` | Yes | Fetching Git, OCI, Helm and bucket sources |
| `kustomize-controller` | Yes | Applying Flux `Kustomization`s |
| `helm-controller` | Yes | Installing and upgrading `HelmRelease`s |
| `notification-controller` | Yes | Sending alerts and receiving webhooks |
| `image-reflector-controller` | No | Scanning image registries for tags (`ImageRepository`, `ImagePolicy`) |
| `image-automation-controller` | No | Writing new image tags back to Git (`ImageUpdateAutomation`) |
| `source-watcher` | No | Building artifacts from other artifacts |

Two flags choose the components. `--components` replaces the default list with the one you give. `--components-extra` adds components to the default list. When you want one more controller, `--components-extra` is the safe choice, because you cannot forget a default one by mistake.

## What happens without the CRD

Before you add anything, see the failure your teammate saw. The `ImageRepository` below asks image-reflector-controller to scan the public `podinfo` image every five minutes.

<!-- astrona:playground:renew -->

Save this as `imagerepository-podinfo.yaml`:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 5m
```

Apply it:

```sh
kubectl apply -f imagerepository-podinfo.yaml
```

The API server refuses the object. `kubectl` reports that it found no match for the kind `ImageRepository` in the version `image.toolkit.fluxcd.io/v1`, and it suggests that the CRDs may need to be installed first. The refusal comes from the API server, before any controller is involved: without the CustomResourceDefinition (CRD), the kind does not exist, so there is nothing to store.

The opposite case is quieter and worse. If the CRD exists but its controller does not run, the API server stores the object and nobody ever acts on it. Its status stays empty, with no `Ready` condition at all. An object with no conditions is a sign that no controller watches its kind.

## Add the image automation controllers

`flux install` is safe to run again on a cluster that already runs Flux. It applies the full set of manifests for the components you name, so the default controllers stay as they are and the extra ones are added. Add both image controllers:

```sh
flux install --components-extra=image-reflector-controller,image-automation-controller
```

The command prints each step: it generates the manifests, applies the CRDs and the Deployments, and waits until every Deployment is ready. When it finishes, the namespace `flux-system` runs six controllers. Your `GitRepository` and Flux `Kustomization` are not touched, because `flux install` only manages the controllers and their CRDs.

The image kinds now exist. Apply the same file again:

```sh
kubectl apply -f imagerepository-podinfo.yaml
```

This time the API server stores the object, and image-reflector-controller starts its first scan. The scan needs outbound internet to reach `ghcr.io`. After a few seconds, read the result:

```sh
flux get images repository podinfo
```

The `Ready` column shows `True`, and the message says the scan was successful and how many tags it found. The same number is in `status.lastScanResult.tagCount` of the object.

## Check the whole installation

`flux check` checks the installation as a whole. It checks that your Kubernetes version is supported, that each Flux controller Deployment is ready, and that the CRDs are installed, and it prints the version of each controller:

```sh
flux check
```

Every line ends in a check mark, including the two image controllers, and the last line says that all checks passed. When a controller is missing or not ready, `flux check` names it and exits with a non-zero code, so you can also use it in a script.

You can now tell a default component from an optional one, read the two failure signs (a refused kind and an object with no conditions), add controllers with `--components-extra` without losing the default ones, and prove the result with `flux check` and a ready object. The open question is how the components stay that way: a cluster installed with `flux install` keeps no record of the change in Git.

## Common pitfalls

> [!WARNING]
> - **Using `--components` when you meant `--components-extra`.** `--components` replaces the default list, so the controllers you did not name are not part of the installation you asked for.
> - **Reading "no matches for kind" as a typing mistake.** It usually means the CRD is not installed. Check with `kubectl api-resources --api-group=image.toolkit.fluxcd.io`.
> - **Trusting an object with no conditions.** If the API server stored the object but no `Ready` condition ever appears, no controller watches that kind.
> - **Expecting the scan to work offline.** An `ImageRepository` scans a real registry, so it needs outbound internet to `ghcr.io`.

## Your mission: Add The Image Automation Controllers

You can now find which controller a kind needs, add optional controllers without losing the default ones, and check the installation. The graded lab gives you a cluster that runs only the default Flux controllers and an `ImageRepository` that cannot be applied, and asks you to add both image controllers and get the `ImageRepository` ready.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-020-01
astrona start ats-094-playground-020-01
```
