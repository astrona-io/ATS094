# OCI, Helm And Bucket Sources

Git is not the only place where desired state lives. Teams publish manifests as container images, charts in Helm repositories, and files in object storage. source-controller handles each of these with its own kind, and all of them produce the same artifact that a Flux `Kustomization` or a `HelmRelease` consumes. This part compares the kinds and shows the one that changes how teams ship configuration: the OCI artifact.

The commands below need the `flux` tool and outbound internet access to `ghcr.io`. They need no running source from earlier parts:

<!-- astrona:playground:renew -->

## OCIRepository

An **OCI artifact** is a set of files stored in a container registry, the same kind of server that stores images. OCI stands for Open Container Initiative, the standard behind the format. An `OCIRepository` makes source-controller pull such an artifact, and it is the registry counterpart of a `GitRepository`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo-manifests
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    semver: ">=6.0.0"
```

The `url` starts with `oci://` and has no tag. The `ref` can name a `tag`, a `semver` range or a `digest`. The revision looks like `6.9.0@sha256:` followed by the digest. A Flux `Kustomization` uses it by setting `sourceRef.kind` to `OCIRepository`. For registries that need authentication, `spec.secretRef` holds a Docker registry Secret, or `spec.provider` selects the identity of a cloud (`aws`, `azure` or `gcp`) so that no password is stored.

## Why OCI instead of Git

An OCI artifact is immutable by digest and is built once by a pipeline. The cluster pulls it from a registry that is close to it, with the same access control as images. It does not need access to the Git server at all, and it scales well when thousands of clusters pull the same artifact. The cost is that a person edits Git, not the registry, so a pipeline must publish the artifact after each merge.

## Push and pull with the flux tool

The `flux` tool creates and reads these artifacts. Pull the demo artifact into a local folder to see what is inside:

```sh
flux pull artifact oci://ghcr.io/stefanprodan/manifests/podinfo:latest --output ./podinfo-manifests
command ls ./podinfo-manifests
```

The folder holds Kubernetes manifests, usually a `kustomization.yaml` and the files it lists. Publishing works the other way. In a pipeline you push a local folder with a version and a source reference:

```sh
flux push artifact oci://ghcr.io/example/manifests/podinfo:1.0.0 \
  --path=./deploy \
  --source="$(git config --get remote.origin.url)" \
  --revision="1.0.0@sha1:$(git rev-parse HEAD)"
```

The command uploads the folder and records the source and revision in the artifact metadata. It needs write access to the registry, so log in first with your registry tool. Promote an artifact without rebuilding it by adding a tag to the same digest:

```sh
flux tag artifact oci://ghcr.io/example/manifests/podinfo:1.0.0 --tag production
flux list artifacts oci://ghcr.io/example/manifests/podinfo
```

The first command adds the tag `production` to the existing artifact. The second lists the tags in the repository. A cluster that follows the tag `production` receives exactly the artifact that was tested.

## HelmRepository and HelmChart

A **Helm chart** is a package of Kubernetes templates. Charts are stored in a Helm repository, either an HTTP server with an `index.yaml` file or an OCI registry. A `HelmRepository` points at one of them:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  url: https://stefanprodan.github.io/podinfo
```

For an OCI registry, set `type: oci` and an `oci://` URL. For the HTTP kind, source-controller downloads and caches the index. A `HelmChart` is the object that selects one chart and version from the repository and stores that chart as an artifact. You rarely create one by hand: a `HelmRelease` describes the chart it needs, and helm-controller creates the `HelmChart` for it.

## Bucket

A `Bucket` makes source-controller fetch files from object storage such as Amazon S3, Google Cloud Storage, Azure Blob Storage or any server that speaks the S3 protocol:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: Bucket
metadata:
  name: configs
  namespace: flux-system
spec:
  interval: 5m
  provider: generic
  bucketName: configs
  endpoint: minio.example.com
  secretRef:
    name: configs-credentials
```

Use it when files are produced outside Git and nobody wants to run a Git server for them. Its artifact has no commit, so the revision is a hash of the content.

## Choosing a kind

The choice follows where the content lives. Use `GitRepository` when people edit manifests in Git and want review and history. Use `OCIRepository` when a pipeline builds configuration and clusters should not reach Git. Use `HelmRepository` for packaged applications from outside, and `Bucket` for files in object storage. The consumer does not change: a Flux `Kustomization` reads an artifact in the same way for all of them.

```sh
flux get sources all
```

The command lists every source kind in one table, so you can compare revisions across kinds.

## Common pitfalls

> [!WARNING]
> - **A tag in the `oci://` URL.** The URL names the repository; the version belongs in `ref`.
> - **`type: oci` left out for an OCI Helm registry.** The default type expects an `index.yaml` over HTTP.
> - **Pushing artifacts without a revision.** The metadata then tells nobody which commit built it.
> - **Following `latest` in production.** A moving tag changes the cluster without a review. Follow a version range or a promoted tag.
