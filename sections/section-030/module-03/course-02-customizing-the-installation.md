# Customizing The Installation

The default Flux installation fits most clusters. Large clusters need more workers and more memory. Strict clusters need fewer permissions. This part shows how to change the controllers without losing the change at the next upgrade.

The commands below use the running cluster and a local folder:

<!-- astrona:playground:renew -->

## Flags of flux install

Many choices are flags of `flux install` and `flux bootstrap`:

| Flag | What it does |
| --- | --- |
| `--components` | The controllers to install. The default is source, kustomize, helm and notification |
| `--components-extra` | Optional controllers on top: `image-reflector-controller` and `image-automation-controller` |
| `--network-policy` | Creates network policies that limit traffic in `flux-system`. It is on by default |
| `--watch-all-namespaces` | Lets the controllers watch every namespace. It is on by default |
| `--cluster-domain` | The cluster domain, when it is not `cluster.local` |
| `--registry` | Pulls the controller images from another registry |
| `--image-pull-secret` | The Secret used to pull the images |
| `--toleration-keys` | Taints that the controllers tolerate |

List them all with `flux install --help`.

```sh
flux install --export --components-extra=image-reflector-controller,image-automation-controller | grep -c "kind: Deployment"
```

## Patches for everything else

Anything that is not a flag is a patch on the exported manifests. Bootstrap writes a `kustomization.yaml` next to `gotk-components.yaml`, and the patches go there. Flux reads it as a normal Kustomize file. Try it on a local folder:

```sh
mkdir -p custom && cd custom
flux install --export > gotk-components.yaml
cat > kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --concurrent=10
    target:
      kind: Deployment
      name: kustomize-controller
YAML
kubectl kustomize . | grep -B2 -A12 "name: kustomize-controller" | grep -n "concurrent"
```

Common changes:

- `--concurrent=<n>` on a controller lets it reconcile more objects at once. The default for kustomize-controller is 4.
- Resource requests and limits on the containers, when the defaults are too small for many objects.
- `--requeue-dependency=<duration>` on kustomize-controller sets how often an object retries while it waits for a dependency. The default is 30 seconds.
- `--no-cross-namespace-refs=true` stops an object in one namespace from referring to a source in another. Use it for multi-tenant clusters.
- `--default-service-account=<name>` makes the controllers apply with a named account instead of their own, for objects that do not set one.

## Keeping a customization

In a bootstrapped cluster, commit the `kustomization.yaml` with the patches next to the components. The Flux `Kustomization` `flux-system` applies the folder, so the patch is part of what Flux applies to itself. Running bootstrap again for an upgrade rewrites `gotk-components.yaml` and keeps your file.

Never edit a controller Deployment with `kubectl edit` in a bootstrapped cluster. Flux applies the folder again and the edit is lost.

## Add a component later

Adding a component is a repeat of install with the extra flag. In a bootstrapped cluster, repeat the bootstrap command with `--components-extra`. The new controllers' manifests are added to `gotk-components.yaml`.

```sh
flux install --components-extra=image-reflector-controller,image-automation-controller
kubectl -n flux-system get deployments
```

## Try it

1. Build the patch above with `kubectl kustomize` and confirm the argument `--concurrent=10` appears for `kustomize-controller` only.
2. Add a resource limit of `1Gi` of memory to the same patch for `source-controller` and check the output.
3. Run `flux install --components-extra=...` on the cluster and list the Deployments. Which two are new?
