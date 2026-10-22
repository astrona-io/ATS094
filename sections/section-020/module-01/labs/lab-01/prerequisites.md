# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to list Deployments and apply a YAML file.
- Explain what a CustomResourceDefinition (CRD) and a controller are.
- Run `flux` commands against a cluster.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- The `flux` command-line tool, version **2.9.6**, on your PATH.
- **Flux 2.9.6** in `flux-system`, with its four default controllers only.
- Gitea in the namespace `gitea`, with the repository `gitops/fleet`. This lab does not need it.

Nothing the task asks you to install has been installed for you.

## Working rules

- Everything is graded on the **final cluster state**, so leave the controllers and the `ImageRepository` in place.
- The scan needs outbound internet to `ghcr.io`.
- `kubectl` and `flux` are available.
