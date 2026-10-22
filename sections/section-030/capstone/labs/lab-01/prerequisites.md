# Prerequisites

Before starting this capstone you should be able to:

- Bootstrap Flux from a Git repository with `flux bootstrap git`.
- Read `flux get`, `flux events` and the `Ready` condition of a Flux object.
- Clone a Git repository, change a file, commit it and push it.

## What the environment gives you

The environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- The **Flux CLI 2.9.6** on your PATH, and Flux 2.9.6 bootstrapped into the cluster from `gitops/fleet`, path `clusters/kind`.
- **Gitea** in the namespace `gitea`, holding `gitops/fleet`.
- podinfo, deployed by a Flux `Kustomization` named `podinfo` that is defined in `clusters/kind/podinfo.yaml`.

Your machine reaches Gitea at `http://gitea.localtest.me:3000` once you run `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal. If `git` cannot resolve the name, add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Working rules

- Everything is graded on the **final cluster state and the final content of `gitops/fleet`**.
- Keep the port-forward running while you use `git` or `flux bootstrap`.
- Fix one fault at a time and check the `Ready` conditions after each fix. One fault can hide another.
