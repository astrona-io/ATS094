# Prerequisites

Before starting this lab you should be able to:

- Read a `GitRepository` and a Flux `Kustomization` and say what each controls.
- Use `flux get`, `flux events` and `flux reconcile`.
- Use `kubectl` to read and change objects in a namespace.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` in `flux-system`, with working credentials for the repository.

## Working rules

- Everything is graded on the **final cluster state**, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- You do not need to change anything in Git for this lab.
