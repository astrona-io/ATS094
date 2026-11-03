# Review, Environments And Debugging

Pushing straight to `main` is the quickest set-up and the least controlled. This part shows how to put a review step in front of the change, how to use different rules per environment, and how to debug the chain when it stops.

The commands below need the chain from the earlier parts:

<!-- astrona:playground:renew -->

## Push to a separate branch

Set `git.push.branch` to a branch other than the checkout branch, and the automation pushes there:

```yaml
spec:
  git:
    checkout:
      ref:
        branch: main
    push:
      branch: image-updates
```

The branch is created from `main` with the new commit. A pull request from `image-updates` to `main` is the review step. After the merge, the cluster follows `main` and applies the change. The automation checks out `main` again on the next run, so the branch contains only the image change. You can open the pull request by hand, with a script, or with the notification `githubdispatch` provider and a workflow.

## Different rules per environment

Use one `ImageRepository` and several policies, one for each environment:

| Environment | Policy | Result |
| --- | --- | --- |
| Staging | `numerical` on a build number, or a `semver` range with pre-releases | Takes every new build |
| Production | `semver` with `~6.5.0` or `6.x` | Takes only released versions |

Each environment has its own `ImageUpdateAutomation`, its own path in Git (such as `./clusters/staging`) and its own marker with the policy name. Promotion is then a matter of what the production policy allows, or of changing the range with a reviewed commit.

## Rollback

The image is a normal line in Git. To go back, revert the commit made by the automation. The automation then sees a policy that selects a newer tag again and writes it again. To stop that, either narrow the policy to exclude the bad version, for example `<6.6.0`, or suspend the automation with `flux suspend image update fleet` while you fix the problem.

## Debugging the chain

Check the links from left to right, and stop at the first one that is wrong:

1. `flux get image repository`: is the tag count greater than zero? If not, check the image name, the Secret and the network.
2. `flux get image policy`: is there a selected tag? If not, check the range, the filter and the tag list.
3. Look for the marker: does the file carry `$imagepolicy` with the right `namespace:name`?
4. `flux get image update`: when did it last run, and is `lastPushCommit` set? If it ran and changed nothing, check `update.path` and the marker.
5. `flux get sources git` and `flux get kustomizations`: did the new commit arrive and apply?

If a push is rejected, the credentials of the `GitRepository` have no write access, or the branch is protected. The message is in the `Ready` condition of the automation.

## Security notes

The automation needs write access to Git, so use a token limited to that one repository. Anyone who can push an image tag that a policy accepts can change what runs in the cluster, so restrict who can push to the registry, and sign images where you can. Use a narrow range rather than `>=0.0.0`.

## Try it

1. Change `git.push.branch` to `image-updates` and trigger a run. What branch exists on the Git server afterwards?
2. Write the policy range for a production environment that takes only patch releases of your current version.
3. Suspend the automation, and confirm with `flux get image update` that it is suspended. Resume it.
