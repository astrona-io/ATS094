# Upgrading, Customizing And Uninstalling Flux

A Flux installation has a life of its own. New versions arrive every few months. Some controllers need more memory, more workers or a flag that is off by default. And one day a cluster is retired, and Flux must leave without taking the applications with it. Each of these is routine work, and each can lose data or availability if you do not know what the command does underneath.

Keep one sentence in mind: **Flux is a set of ordinary manifests, so you upgrade it by changing the manifests, customize it by patching them, and remove it by deleting them in the right order.** A bootstrapped cluster does all three through Git.

The module has four parts. The first part upgrades Flux, with a check before and after. The second part customizes the controllers with flags, resources and patches. The third part uninstalls Flux and keeps the workloads, and a graded lab follows it. The fourth part rebuilds a cluster from Git and from exports.

## Learning objectives

After this module you can:

- Check a cluster before an upgrade with `flux check --pre`, and compare versions with `flux version`.
- Upgrade Flux with `flux install` or by running `flux bootstrap` again with a newer CLI.
- Customize the controllers with `flux install` flags and with patches in `flux-system/kustomization.yaml`.
- Add optional components such as the image automation controllers.
- Remove Flux with `flux uninstall` without losing applied workloads, and delete a single Flux `Kustomization` safely.
- Rebuild a cluster from Git, and save what is not in Git with `flux export`.

## Before you start

You need the basics of Flux: a `GitRepository`, a Flux `Kustomization`, `flux get` and `flux check`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folder `apps/podinfo` holds the `podinfo` application |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
