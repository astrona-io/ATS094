# Drift Detection, Ordering And Post-Renderers

A release is installed once and upgraded when its inputs change. In between, someone may change an object by hand, a chart may need another release first, or a chart may not expose the field you need. This part covers the three tools for those cases.

The commands below need the `HelmRelease` `podinfo` from the earlier parts:

<!-- astrona:playground:renew -->

## Drift detection

By default, helm-controller does not look at the live objects between upgrades. A change made with `kubectl` stays until the next upgrade. Drift detection changes that:

```yaml
spec:
  driftDetection:
    mode: enabled
```

With `mode: enabled`, the controller compares the live objects with the manifests of the release on every reconcile, and corrects differences. With `mode: warn`, it only reports them in events and metrics. Try it on the Deployment:

```sh
kubectl -n flux-system patch helmrelease podinfo --type=merge \
  -p '{"spec":{"driftDetection":{"mode":"enabled"}}}'
flux reconcile helmrelease podinfo
kubectl -n podinfo scale deployment podinfo --replicas=5
flux reconcile helmrelease podinfo
kubectl -n podinfo get deployment podinfo
```

The replica count returns to the value from the release. Some fields are changed on purpose by other controllers, for example the replicas set by an autoscaler. Exclude them with `spec.driftDetection.ignore`, a list of JSON pointer paths and optional targets, so that the controller does not fight with the autoscaler.

## Ordering with dependsOn

`spec.dependsOn` lists releases that must be ready first, in the form of `name` and optionally `namespace`:

```yaml
spec:
  dependsOn:
    - name: ingress-nginx
      namespace: flux-system
```

The release waits until every listed `HelmRelease` is `Ready`. Use it for charts that depend on a CRD or a controller from another chart. A `HelmRelease` can depend only on other `HelmRelease` objects. The CRDs of a chart are installed by Helm with the chart; control how they are upgraded with `spec.install.crds` and `spec.upgrade.crds`, which accept `Skip`, `Create` and `CreateReplace`.

## Post-renderers

Sometimes the chart does not expose the field you need to change. A post-renderer changes the rendered manifests before they are applied, without a fork of the chart. The kind that Flux supports is `kustomize`:

```yaml
spec:
  postRenderers:
    - kustomize:
        patches:
          - target:
              kind: Deployment
              name: podinfo
            patch: |
              apiVersion: apps/v1
              kind: Deployment
              metadata:
                name: podinfo
                annotations:
                  example.com/owner: platform-team
        images:
          - name: ghcr.io/stefanprodan/podinfo
            newTag: 6.15.0
```

The patches and the image changes use the same format as in a Flux `Kustomization`. They run after the chart is rendered and before the objects are applied. Use a post-renderer for a small change that the chart does not offer. If you need many, consider whether a different chart or a Flux `Kustomization` fits better.

## Helm or Kustomize

Choose Helm when you consume a chart from a vendor, when the application ships configuration through values, or when you need Helm's release history and rollback. Choose a Flux `Kustomization` with plain manifests when you own the manifests and want the diff in Git to be the manifest itself. Many clusters use both: Helm for third-party software, and Kustomize for their own applications.

## Try it

1. Turn on drift detection, scale the Deployment by hand, and confirm that the replicas return.
2. Add a post-renderer that sets an annotation on the Deployment, and read it from the running object.
3. Set `mode: warn`, scale again, and read the events with `kubectl -n flux-system get events`. What do you see, and what happens to the replicas?
