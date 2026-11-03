# The Reconciliation Loop In Depth

A Flux `Kustomization` that shows `READY False` gives you one line of text. To act on that line, you need to know what the controller was doing when it wrote it: which step failed, how long it will wait before the next try, and what it needs from other objects before it may run at all. This module opens the reconciliation loop and shows its parts.

Every Flux controller runs the same pattern for every object it owns. It reads the object, compares the desired state with the current state, changes what differs, and writes the result into the `status` of the object. Then it waits and starts again. The pattern is the same for a `GitRepository`, a Flux `Kustomization` and a `HelmRelease`, so what you learn here applies to all of them.

Keep one sentence in mind: **an object is healthy only when its `Ready` condition is `True` for the latest generation, and a controller tells you why it is not in the status and in the events.** Every command in this module reads or tests that sentence.

The module has four parts. The first part shows what a controller does on each run and how to read `Ready`, `Reconciling` and `Stalled`. the second explains how often each controller runs, how it retries, and how it decides that applied objects are healthy. the third makes one Flux `Kustomization` wait for another, with a graded lab right after it. the fourth shows who owns which field of an object, and how `flux trace` and `flux tree` find the Flux objects behind a live resource.

## Learning objectives

After this module you can:

- Describe the steps of one reconciliation run and say where each result is written.
- Read the conditions `Ready`, `Reconciling` and `Stalled`, `observedGeneration`, `lastAppliedRevision` and `lastAttemptedRevision` of a Flux `Kustomization`.
- Set `interval`, `retryInterval` and `timeout`, and predict when the next run happens after a success and after a failure.
- Use `wait` and `healthChecks`, and explain why they cannot both be active at the same time.
- Order two Flux `Kustomization` objects with `dependsOn`, and read the message that says a dependency is missing or not ready.
- Explain server-side apply, field managers and `force`, and find the Flux objects that manage a resource with `flux trace` and `flux tree`.

## Before you start

You need the basics of Flux: a `GitRepository` and a Flux `Kustomization`, and the commands `flux get`, `flux events` and `flux reconcile`. You also need `kubectl get -o jsonpath` to read single fields.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | Two folders: `infrastructure` (a namespace `platform` and a Deployment `cache`) and `apps/podinfo` (a namespace `podinfo`, a Deployment with 2 replicas and a Service). Each folder has a Kustomize file `kustomization.yaml` |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
