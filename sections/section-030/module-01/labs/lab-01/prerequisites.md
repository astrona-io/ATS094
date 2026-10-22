# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to inspect objects in a namespace.
- Clone a Git repository, commit a file and push it with `git`.
- Read a Flux `Kustomization` object and say which source and path it uses.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- The **Flux CLI 2.9.6** on your PATH. Flux itself is **not** installed in the cluster.
- **Gitea**, a Git server, in the namespace `gitea`. It holds the repository `gitops/fleet` with the podinfo application under `apps/podinfo` and an empty folder `clusters/kind`.
- The lab-only Gitea user `gitops` with the password `gitops-password`.

Your machine reaches Gitea at `http://gitea.localtest.me:3000` once you run `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal. The name `gitea.localtest.me` resolves to `127.0.0.1`, and the lab makes the same name point at Gitea inside the cluster, so Flux uses the same address. If `git` cannot resolve the name, add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final cluster state and the final content of `gitops/fleet`**.
- Keep the port-forward running while you use `git` or `flux bootstrap`. The controllers in the cluster do not need it.
- Change things through Git once Flux is running. An object you apply with `kubectl` is not managed by Flux, and the grader checks that.
