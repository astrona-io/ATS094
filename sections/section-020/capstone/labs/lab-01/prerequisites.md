# Prerequisites

Before starting this capstone you should be able to:

- Name the Flux controllers and the kinds each one owns.
- Read `flux check`, `flux get`, `flux events` and `flux logs`.
- Change one field of an existing object with `kubectl patch` or `kubectl edit`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- The `flux` command-line tool, version **2.9.6**, on your PATH.
- **Flux 2.9.6** in `flux-system`, with its four default controllers, prepared as the task describes.
- Gitea in the namespace `gitea`, with the repository `gitops/fleet`. The user `gitops` with the password `gitops-password` can read it; the Secret `fleet-auth` in `flux-system` holds those lab-only credentials for Flux.

## Working rules

- Everything is graded on the **final cluster state**.
- Change one thing at a time and check again with `flux get`.
- You do not need to clone the repository. If you want to, run `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal and clone `http://gitea.localtest.me:3000/gitops/fleet.git`.
