# Kustomize Controller In Depth

kustomize-controller is the Flux controller that changes a cluster. It reads an artifact from a source, builds the manifests, replaces variables, applies the result, removes what disappeared from Git, and waits until the workloads are healthy. Everything you describe in a Flux `Kustomization` is one of these steps.

A Flux `Kustomization` (`kustomize.toolkit.fluxcd.io/v1`) is not the same thing as a `kustomization.yaml` file. The `kustomization.yaml` file belongs to the Kustomize tool and lives in Git. The Flux `Kustomization` is a Kubernetes object that tells the controller where in a source to look and how to apply it. A Flux `Kustomization` can build a folder that has no `kustomization.yaml` at all: the controller then creates one that lists every manifest in the folder.

Keep one sentence in mind: **the controller builds first, substitutes second and applies last, so every error belongs to one of these three steps.** Knowing the step tells you where to look.

The module has four parts. The first part builds a folder with Kustomize and shows the same build from the Flux side. The second part changes the result from the Flux `Kustomization` itself with patches, images and a target namespace. The third part replaces variables with `postBuild`, and a graded lab follows it. The fourth part limits what the controller is allowed to do, with a service account and with tenant rules.

## Learning objectives

After this module you can:

- Explain the order build, substitute, apply, prune, wait.
- Build a base and an overlay, and preview the result with `flux build kustomization` and `flux diff kustomization`.
- Change objects without editing the files in Git, with `patches`, `images`, `namePrefix` and `targetNamespace`.
- Replace variables with `postBuild.substitute` and `postBuild.substituteFrom`, use defaults, and switch the replacement off for one object.
- Run a Flux `Kustomization` as a service account, and explain what happens when it has too few or too many permissions.
- Read the `Ready` condition of a Flux `Kustomization` to tell a build error from a substitution error from an apply error.

## Before you start

You need the basics of Flux and the earlier modules: a `GitRepository`, a Flux `Kustomization`, and the commands `flux get`, `flux reconcile` and `kubectl get`. You also need to know what a YAML manifest for a Deployment looks like.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folders `apps/layered` (a base and a `staging` overlay) and `apps/templated` (a Deployment with variables) are added next to the `apps/podinfo` application |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
