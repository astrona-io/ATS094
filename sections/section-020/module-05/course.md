# Notifications And Webhooks

Flux works without anyone watching it. That is only safe if the people who run it hear about failures, and if the outside world can tell Flux when something changed. notification-controller does both. It sends events out, to chat, to incident tools and back to Git hosts. It also receives webhooks, so a push to a repository or a new image in a registry starts a reconcile right away instead of at the next interval.

Three kinds of objects belong to it. A `Provider` says where messages go. An `Alert` says which events go to which `Provider`. A `Receiver` creates a URL that outside systems call to start a reconcile.

Keep one sentence in mind: **an Alert connects event sources to a Provider, and it matches nothing unless the names, namespaces and severity are right.** The Alert is a filter, and the most common mistake is a filter that selects nothing.

The module has four parts. The first part shows the events that Flux creates and how notification-controller gets them. The second part builds a `Provider` and an `Alert`, and a graded lab follows it. The third part sends commit statuses back to a Git host. The fourth part receives webhooks with a `Receiver`.

## Learning objectives

After this module you can:

- Read Flux events with `flux events` and `kubectl events`, and explain their fields.
- Create a `Provider` and an `Alert`, with event sources, severity and exclusions.
- Keep the address or token of a `Provider` in a Secret.
- Explain how commit status notifications work and what they need.
- Create a `Receiver`, find its webhook path, and call it.
- Debug an `Alert` or `Receiver` that does nothing.

## Before you start

You need the basics of Flux: a `GitRepository`, a Flux `Kustomization`, `flux get` and `flux reconcile`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`, including notification-controller. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folder `apps/podinfo` holds the `podinfo` application |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
