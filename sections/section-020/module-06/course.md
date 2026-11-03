# Image Automation In Depth

Flux can do more than apply what is in Git. With the image automation controllers, Flux can watch a container registry, decide which tag is the newest one that you allow, and write that tag back to Git. The change is a commit like any other, so the history, the review and the rollback of normal GitOps still work.

Three objects form a chain. An `ImageRepository` scans a registry for tags. An `ImagePolicy` selects one tag from the scan. An `ImageUpdateAutomation` edits the files in Git that carry a marker for that policy, commits and pushes. A Flux `Kustomization` then applies the new commit as usual.

The first two objects belong to image-reflector-controller. The third belongs to image-automation-controller. Neither is installed by default; you add them with `flux install --components-extra=image-reflector-controller,image-automation-controller`, or with the same flag on `flux bootstrap`. Your playground has them already.

Keep one sentence in mind: **the automation never touches the cluster, it only writes to Git.** If the cluster does not change, check the chain from left to right: scan, select, edit, push, apply.

The module has four parts. The first part scans a registry. The second part selects a tag with a policy. The third part writes the tag to Git, and a graded lab follows it. The fourth part covers the workflows around it: reviewed changes, several environments and debugging.

## Learning objectives

After this module you can:

- Create an `ImageRepository` and read what it scanned, including how to give it registry credentials.
- Select a tag with a `semver`, `alphabetical` or `numerical` policy, and filter tags with a pattern.
- Mark an image in a manifest and configure an `ImageUpdateAutomation` that commits and pushes.
- Push changes to a separate branch so that they can be reviewed.
- Debug a chain that does not update, one link at a time.

## Before you start

You need the basics of Flux: a `GitRepository`, a Flux `Kustomization`, `flux get` and `flux reconcile`. You also need to know what an image tag is.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, including the two image controllers. No repository is connected yet |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `gitops/fleet` | The folder `apps/podinfo` holds the `podinfo` application. Its Deployment has an image policy marker |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq`; you run `git` on your own machine |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`. On your machine that works only while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal. The image registry is `ghcr.io`, so the parts need outbound internet access.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
