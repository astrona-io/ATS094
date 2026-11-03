# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Image automation

## Scenario

The application `podinfo` runs from the repository `gitops/fleet`. Its Deployment in `apps/podinfo` runs the image `ghcr.io/stefanprodan/podinfo:6.5.0` and carries an image policy marker for the `ImagePolicy` `podinfo`. The team wants Flux to follow the newest 6.x release of the image: it should find the tag, write it to Git and apply it.

A colleague created an `ImageRepository`, an `ImagePolicy` and an `ImageUpdateAutomation` in the namespace `flux-system`. They apply without an error, but the application still runs 6.5.0.

## Your task

1. Find out why the `ImagePolicy` `podinfo` does not select a tag. Fix it so that it selects the newest 6.x version.
2. Find out why the `ImageUpdateAutomation` `fleet` makes no change to Git, and fix it.
3. Confirm that Flux wrote the new tag to the repository and applied it.

## Constraints

- **Flux must make the change.** Do not edit the image in Git yourself and do not run `kubectl set image` or `kubectl edit` on the Deployment.
- Keep the names of the three image objects and the marker in Git. Do not change anything in the repository by hand.
- Do not suspend any object.

## Done when

- The `ImagePolicy` `podinfo` is `Ready` and selects a tag that starts with `6.`.
- The `ImageUpdateAutomation` `fleet` has pushed a commit.
- The Deployment `podinfo` in the namespace `podinfo` runs the tag that the policy selects, and that tag is not `6.5.0`.
