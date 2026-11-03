# GitOps Terminology And Delivery Patterns

Flux has its own words, and so does GitOps. People use them loosely: "sync", "deploy", "source", "promote". This module fixes the meaning of each word, ties it to a Flux object or field, and then uses the words to build something real: one application in two environments, staging and production, from one repository.

Keep one sentence in mind: **Git holds the desired state, the cluster holds the actual state, and Flux is the process that makes the second equal the first.** Every term in this module is a part of that sentence.

The module has four parts. The first part defines desired and actual state and the four OpenGitOps principles. The second part names every Flux term you meet in `flux get` and in the status of an object. The third part builds two environments from a base and two overlays, and a graded lab follows it. The fourth part covers promotion from staging to production, and rollback by reverting a commit.

## Learning objectives

After this module you can:

- Define desired state, actual state, drift and reconciliation, and name the four OpenGitOps principles.
- Explain the difference between push-based and pull-based delivery.
- Use the Flux terms source, artifact, revision, reconcile, apply, prune, health check and inventory correctly.
- Lay out one application for several environments with a base and overlays.
- Give each environment its own Flux `Kustomization` with its own path and namespace.
- Promote a change from staging to production, and roll back by reverting a commit.

## Before you start

You need a `kubectl` and a `flux` command on your machine, and you should have seen a `GitRepository` and a Flux `Kustomization` before.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folder `apps/podinfo` holds a base and two overlays, `staging` and `production`. The folder `infrastructure/namespaces` creates the two namespaces |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
