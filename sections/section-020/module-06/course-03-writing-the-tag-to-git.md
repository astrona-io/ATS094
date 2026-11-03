# Writing The Tag To Git

The last link is the one that changes Git. An `ImageUpdateAutomation` clones the repository, finds markers, rewrites the lines that carry them, commits and pushes.

The commands below need the `ImagePolicy` `podinfo` from the earlier parts, the `GitRepository` `fleet`, and a Flux `Kustomization` `podinfo` for the path `./apps/podinfo`:

<!-- astrona:playground:renew -->

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
flux create kustomization podinfo \
  --source=GitRepository/fleet --path=./apps/podinfo \
  --prune=true --wait=true --interval=1m
```

## Markers

A marker is a comment on the line that holds the image. It names the policy as `namespace:name`:

```yaml
image: ghcr.io/stefanprodan/podinfo:6.15.0 # {"$imagepolicy": "flux-system:podinfo"}
```

The automation replaces the value in front of the comment with the selected image. You can also replace only a part. The suffixes `:name`, `:tag` and `:digest` select the image name, the tag or the digest, so a Helm values file with a separate `tag:` key can be updated:

```yaml
tag: 6.15.0 # {"$imagepolicy": "flux-system:podinfo:tag"}
```

The marker is the link between the policy and the file. A marker with a wrong policy name or wrong namespace is ignored.

## The automation

```sh
flux create image update fleet \
  --git-repo-ref=fleet \
  --git-repo-path=./apps/podinfo \
  --checkout-branch=main \
  --push-branch=main \
  --author-name=fluxcdbot \
  --author-email=fluxcdbot@example.com \
  --commit-template='Update images: {{ range .Changed.Changes }}{{ .NewValue }} {{ end }}'
flux get image update
```

The important fields:

| Field | Meaning |
| --- | --- |
| `sourceRef` | The `GitRepository` to clone. Its credentials are used to push, so they need write access |
| `git.checkout.ref` | The branch to start from |
| `git.push.branch` | The branch to push to. If it differs from the checkout branch, the branch is created |
| `git.commit.author` and `messageTemplate` | Who is the author, and the commit message as a Go template |
| `update.strategy` | `Setters`, the marker-based strategy |
| `update.path` | The folder to search for markers, relative to the root of the repository |

After a run that changed files, the status holds `lastPushCommit` and `lastPushTime`. A run without a match changes nothing, which is not an error. The most common reason is a path that does not contain the marked file.

## The full path

After a push, the `GitRepository` fetches the new commit, and the Flux `Kustomization` applies it. The running Deployment gets the new tag:

```sh
kubectl -n flux-system get imageupdateautomation fleet \
  -o jsonpath='{.status.lastPushCommit}{"\n"}'
flux reconcile source git fleet
flux reconcile kustomization podinfo
kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

## Try it

1. Create the automation and wait for a run. Does `lastPushCommit` have a value?
2. Pull the repository on your machine and read `git log -3`. Who is the author?
3. Change `update.path` to a folder without markers, and run `flux reconcile image update fleet`. Does the status change?

## Your mission: Make The Image Policy Select And Update

You can now follow a tag from the registry to Git. The graded lab gives you a chain that is built but does nothing: the policy selects nothing, and the automation looks in the wrong place. Fix both so that Flux updates the application.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-020-06
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/module-06/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-06/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-020-06
astrona start ats-094-playground-020-06
```
