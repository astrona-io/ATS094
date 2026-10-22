# Prerequisites

Before starting this capstone you should be able to:

- Read a `GitRepository` and a Flux `Kustomization`, including `prune`, `suspend` and `.status.inventory`.
- Use `flux get`, `flux events`, `flux suspend`, `flux resume` and `flux reconcile`.
- Clone a repository, edit files, commit and push with `git`.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). On your machine, the repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal. If the name does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.
- The `GitRepository` `fleet`, the Flux `Kustomization` `podinfo`, and the Secret `fleet-auth` in `flux-system`, in the state the task describes.

## Working rules

- Everything is graded on the **final state of the cluster and of Git**. Leave your commits pushed and your fixes in place.
- Change the application only through Git. The grader reads the repository as well as the cluster.
- The grader changes the cluster on purpose in its last check and expects Flux to put it back.
