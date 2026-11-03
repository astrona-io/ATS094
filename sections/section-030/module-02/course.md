# Repository Structure And Cluster Layout

Flux does not care how a repository is laid out. It applies the folder that a `path` points at. But a layout decides how easy it is to add a cluster, to give a team its own area, to apply things in the right order, and to find out what runs where. This module compares the common choices and builds the layout that the Flux documentation recommends for a single cluster, then extends it to several.

Keep one sentence in mind: **a Flux `Kustomization` applies one folder, so the folders are the structure, and the dependencies between Flux `Kustomization` objects are the order.** A layout is a set of folders plus the objects that point at them.

The module has four parts. The first part compares one repository with many. The second part builds the folder layout with `apps`, `infrastructure` and `clusters`. The third part orders infrastructure before applications with `dependsOn` and `wait`, and a graded lab follows it. The fourth part runs several clusters from one repository.

## Learning objectives

After this module you can:

- Compare a monorepo, a repository per environment and a repository per team, and name what each costs.
- Lay out `apps`, `infrastructure` and `clusters` folders for one cluster.
- Explain why `infrastructure` is split into controllers and configuration.
- Order Flux `Kustomization` objects with `dependsOn`, `wait` and `healthChecks`.
- Run several clusters from one repository with a base, overlays and `postBuild` variables.
- Debug a Flux `Kustomization` that points at the wrong source, path or dependency.

## Before you start

You need the basics of Flux: a `GitRepository`, a Flux `Kustomization`, `flux get` and `flux reconcile`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folders `apps`, `infrastructure/controllers`, `infrastructure/configs` and `clusters/kind` |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
