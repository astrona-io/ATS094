# Summary

The image automation controllers let Flux find new image tags and write them to Git. This module followed the chain from the registry to the running pod and showed where it breaks.

## What you learned

An `ImageRepository` scans a registry for the tags of one image, with credentials from a Secret or from the identity of the cloud provider. An `ImagePolicy` selects one tag with `semver`, `alphabetical` or `numerical` rules, optionally after `filterTags`. The result is in `status.latestRef`.

An `ImageUpdateAutomation` clones a `GitRepository`, searches `update.path` for markers of the form `# {"$imagepolicy": "namespace:name"}`, edits the lines, commits with the configured author and pushes. The `:name`, `:tag` and `:digest` suffixes update a part of an image. It changes only Git. A Flux `Kustomization` applies the new commit.

Pushing to a separate branch allows a review. Several policies and automations give each environment its own rules. A rollback is a revert in Git, together with a narrower policy or a suspended automation so that the same tag is not selected again.

The key facts to remember are these:

- The chain is scan, select, edit, push, apply. Debug it from left to right.
- A policy range that matches nothing, and an update path without markers, are silent failures.
- The automation needs write access to Git and nothing more.
- Restrict who can push images that a policy accepts.
- Keep a human review step where a mistake would be expensive.

<!-- astrona:playground:destroy -->
