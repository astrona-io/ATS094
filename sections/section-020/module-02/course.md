# Source Controller And Artifacts

Every Flux deployment starts with a source. Before any manifest reaches the cluster, source-controller must fetch it, check it and turn it into a file that other controllers can read. When a deployment shows old or wrong content, the cause is nearly always here: the wrong reference, the wrong credentials, or a source that quietly stopped updating.

source-controller owns five kinds of source objects: `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart` and `Bucket`. All of them produce the same output, an **artifact**: a compressed archive plus a revision and a digest. The other controllers never talk to Git or to a registry. They read artifacts.

Keep one sentence in mind: **the revision in the source status is the single answer to the question "what is Flux deploying right now?"** Every command in this module reads or changes that revision.

The module has four parts. The first part shows what an artifact is and how to read the status of a source. The second part chooses what to fetch: a branch, a tag, a semantic version range or a commit, and which files to include or ignore. The third part sets up authentication with passwords, tokens, SSH keys and certificates, and a graded lab follows it. The fourth part covers the other source kinds: OCI artifacts, Helm repositories and buckets.

## Learning objectives

After this module you can:

- Describe an artifact and read `status.artifact` (URL, revision, digest) of a source.
- Use `flux get sources`, `flux reconcile source` and `flux suspend source`.
- Follow a branch, a tag, a semantic version range or a commit with `spec.ref`.
- Limit what is stored with `spec.ignore` and combine repositories with `spec.include`.
- Create credentials for HTTP, SSH and TLS with `flux create secret`, and read the error when they are wrong.
- Explain how `OCIRepository`, `HelmRepository` and `Bucket` differ from `GitRepository`, and use `flux push artifact` and `flux pull artifact`.

## Before you start

You need the basics of Flux: a `GitRepository`, a Flux `Kustomization`, and the commands `flux get` and `flux reconcile`. You also need basic Git, including tags.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folder `apps/podinfo` holds the `podinfo` application: a namespace, a Deployment with 2 replicas, a Service, and a Kustomize file |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal. The last part needs outbound internet access to `ghcr.io`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
