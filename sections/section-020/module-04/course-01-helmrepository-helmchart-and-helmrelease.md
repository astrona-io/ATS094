# HelmRepository, HelmChart And HelmRelease

A Helm release needs three things: a place to get the chart, the chart itself, and an instruction to install it. Flux gives each its own object. This part creates all three and shows where the result lives.

The commands below need the Flux controllers in the namespace `flux-system`:

<!-- astrona:playground:renew -->

## The HelmRepository

A `HelmRepository` points source-controller at a chart repository. source-controller downloads the index of the repository, which lists every chart and version:

```sh
flux create source helm podinfo \
  --url=https://stefanprodan.github.io/podinfo \
  --interval=5m
flux get sources helm
```

The source is `Ready` and its revision is a digest of the index. A repository can also be an OCI registry: set `type: oci` and an `oci://` URL, and the charts are pulled as OCI artifacts. For authentication, `spec.secretRef` works like it does for Git.

## The HelmRelease

A `HelmRelease` says what to install. Create one and export it first, to see the YAML:

```sh
flux create helmrelease podinfo \
  --source=HelmRepository/podinfo \
  --chart=podinfo \
  --chart-version="6.x" \
  --release-name=podinfo \
  --target-namespace=podinfo \
  --create-target-namespace=true \
  --export
```

The result is an object of the kind `HelmRelease` with the API version `helm.toolkit.fluxcd.io/v2`. The important fields are `spec.interval`, `spec.chart.spec` (with `chart`, `version` and `sourceRef`), `spec.releaseName`, `spec.targetNamespace` and `spec.values`. Apply it, by running the same command without `--export`:

```sh
flux create helmrelease podinfo \
  --source=HelmRepository/podinfo --chart=podinfo --chart-version="6.x" \
  --release-name=podinfo --target-namespace=podinfo \
  --create-target-namespace=true
flux get helmreleases
```

The object lives in `flux-system`, and the application in the namespace `podinfo`. The two are separate on purpose: the `HelmRelease` is configuration, and `targetNamespace` is where the chart's objects go.

## The HelmChart in between

When a `HelmRelease` names `spec.chart.spec`, Flux creates a `HelmChart` object in the same namespace, named `<namespace>-<name>`:

```sh
kubectl -n flux-system get helmchart
kubectl -n flux-system get helmchart flux-system-podinfo \
  -o jsonpath='{.status.artifact.revision}{"\n"}'
```

source-controller downloads the matching chart version, packages it as an artifact, and helm-controller reads that artifact. The `version` field accepts a semantic version range, as `6.x` does, so a new compatible chart is picked up at the next interval. This is also where a chart problem appears first. If no version matches, the `HelmChart` is not ready, and its message says so. The `HelmRelease` then reports that the chart is not ready.

## Where the release is stored

Helm records every release as a Secret of the type `helm.sh/release.v1` in the storage namespace, which is the target namespace by default:

```sh
kubectl -n podinfo get secrets
```

The Secret is named `sh.helm.release.v1.podinfo.v1`, and each upgrade adds a new revision. The Secrets hold the chart, the values and the rendered manifests, compressed. They are how `helm list` and `helm history` work, and how the controller knows what is installed. Do not edit or delete them by hand. The number of kept revisions is limited by `spec.maxHistory`.

## The release name

The release name decides the names of many objects. Without `spec.releaseName`, the name is the name of the `HelmRelease`, and when `targetNamespace` is set it is prefixed with the target namespace. A `HelmRelease` named `podinfo` with `targetNamespace: podinfo` would then become `podinfo-podinfo`. Set `releaseName` explicitly so that the name is the same everywhere.

## Try it

1. Create the `HelmRepository` and the `HelmRelease`, and wait for both to be `Ready`.
2. List the `HelmChart` objects, and read the revision of the one for `podinfo`.
3. Find the release Secret in the namespace `podinfo`. What revision number does it have?
