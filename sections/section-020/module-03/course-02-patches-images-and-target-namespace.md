# Patches, Images And Target Namespace

Sometimes the files in Git are right for most clusters and wrong for one field. The Flux `Kustomization` can change the built result itself, so you do not need an overlay folder for a small change. These changes happen after the build and before the apply.

The commands below need the Flux `Kustomization` `layered` from the earlier part, or any Flux `Kustomization` that applies a Deployment:

<!-- astrona:playground:renew -->

## Patches

The field `spec.patches` takes a list of patches. Each patch has the patch itself and a `target` that says which objects it applies to. The patch can be a strategic merge patch or a JSON 6902 patch. This one is a strategic merge patch that adds an annotation to every Deployment:

```yaml
spec:
  patches:
    - target:
        kind: Deployment
      patch: |
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: not-used
          annotations:
            example.com/owner: platform-team
```

When a `target` is set, the name in the patch is ignored, and the patch applies to every object that matches the target. A target can select by `kind`, `name`, `namespace`, `labelSelector` and `annotationSelector`. A patch without a match does nothing. Add the patch with `kubectl edit`, `kubectl patch` or in Git, and read the result:

```sh
kubectl -n flux-system patch kustomization layered --type=merge -p '
spec:
  patches:
    - target:
        kind: Deployment
      patch: |
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: not-used
          annotations:
            example.com/owner: platform-team
'
flux reconcile kustomization layered
kubectl -n layered get deployment layered -o jsonpath='{.metadata.annotations}{"\n"}'
```

Patches in the Flux `Kustomization` are useful for one environment-specific field, or for objects you do not own, such as the manifests of a Helm chart or a third-party install file. Many patches, or patches that change the meaning of the application, belong in an overlay in Git where they can be reviewed with the rest.

## Images

The field `spec.images` changes the image name, tag or digest of every container that uses a given image, without a patch:

```yaml
spec:
  images:
    - name: ghcr.io/stefanprodan/podinfo
      newTag: 6.15.0
```

The `name` is the image as written in the manifest, and `newName`, `newTag` and `digest` replace the parts. This is how one set of manifests can run another version in another cluster. Image update automation, which is part of the image controllers, writes to the same kind of field in Git; this field is the manual version of it.

## Names and metadata

`spec.namePrefix` and `spec.nameSuffix` add text to the name of every object, which lets two copies of the same application live in one namespace. `spec.commonMetadata` adds labels and annotations to every object in the build:

```yaml
spec:
  commonMetadata:
    labels:
      team: platform
```

Use it for ownership labels that your tools search for. Do not change names of objects that already run unless you intend a replacement: a new name is a new object, and with `prune: true` the old one is deleted.

## targetNamespace

`spec.targetNamespace` sets the namespace of every namespaced object in the build. It overrides the namespace written in the manifests. Cluster-scoped objects, such as a Namespace, are not changed. This helps when the same manifests are installed once per team, each in its own namespace:

```yaml
spec:
  targetNamespace: team-a
```

It also causes a common failure. If `targetNamespace` names a namespace that does not exist, the controller cannot create the namespaced objects. The controller does not create the namespace for you. Include a Namespace manifest in the build, or create it first. Check the field when objects land in a different place than the manifests say:

```sh
kubectl -n flux-system get kustomization layered -o jsonpath='{.spec.targetNamespace}{"\n"}'
```

An empty answer means the namespaces in the manifests are used.

## Order of the steps

The controller applies these changes in a fixed order: it builds the folder, then applies `patches`, `images`, `namePrefix`, `nameSuffix`, `commonMetadata` and `targetNamespace`, and then substitutes variables. A variable inside a patch is therefore replaced after the patch has been merged. The next part uses this.

## Try it

1. Add the annotation patch to `layered` and check that the annotation appears on the Deployment.
2. Add an `images` entry with `newTag: 6.14.0`, reconcile, and read the image of the running pod. Remove the entry again and reconcile, and read the image.
3. Set `targetNamespace` to a namespace that does not exist, and read the `Ready` message. Set it back to an empty value.
