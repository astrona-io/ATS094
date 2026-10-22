# Reconcile A Cluster From Git With Flux

A Deployment in Git says `replicas: 2`. Someone runs `kubectl scale --replicas=5` during an incident and forgets to change it back. A week later, nobody knows whether five is a decision or an accident. With GitOps, that question has a fixed answer: Git is right, and an agent in the cluster changes the cluster back.

Flux is that agent. It runs inside the cluster as a set of controllers. Each controller watches its own kind of Kubernetes object and keeps doing one job over and over. In this module two of those objects do all the work: a `GitRepository`, which tells Flux where the repository is and which branch to follow, and a Flux `Kustomization`, which tells Flux which folder of that repository to apply. The Flux `Kustomization` is a Flux object; it is not the Kustomize file `kustomization.yaml`, although it uses that file when the folder has one.

Keep one sentence in mind: **a change reaches the cluster only through a commit, and anything else is drift that Flux undoes.** Every command in this module tests that sentence.

The module has three parts. **GitOps Principles And Pull-Based Delivery** explains the four OpenGitOps principles, compares a pull-based agent with a push-based pipeline, and shows the Flux controllers already running in your playground. **Your First GitRepository And Kustomization** points Flux at the repository, deploys `podinfo` from it, and changes the application with a commit. A graded lab follows the second part. **Drift Correction And Pruning** changes the cluster by hand and deletes a file from Git, and shows what Flux does in each case.

## Learning objectives

After this module you can:

- Name the four OpenGitOps principles and explain each one with an example from the playground.
- Explain the difference between push-based and pull-based delivery, and say where the credentials live in each.
- Create a Git credentials Secret with `flux create secret git`.
- Write and apply a `GitRepository` and a Flux `Kustomization`, and say which controller reconciles each one.
- Read `flux get sources git`, `flux get kustomizations` and `flux events`, and find the revision and the reason for a failure.
- Change an application with a Git commit and force a reconciliation with `flux reconcile kustomization --with-source`.
- Predict what Flux does after a manual change, after a file is deleted from Git, and while a Flux `Kustomization` is suspended.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, labels, and the commands `kubectl get`, `kubectl apply` and `kubectl describe`. You also need basic Git: `clone`, `commit` and `push`. You do not need to know Flux or Kustomize yet.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The Flux command-line tool `flux` on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folder `apps/podinfo` holds the `podinfo` application: a namespace, a Deployment with 2 replicas, a Service, and a Kustomize file `kustomization.yaml` that lists them |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository has one address that works both on your machine and inside the cluster: `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine it works only while a port-forward to Gitea runs in a second terminal; the parts start it when they need it. The server uses plain HTTP and a password because it is a lab. A real Git server uses HTTPS or SSH.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
