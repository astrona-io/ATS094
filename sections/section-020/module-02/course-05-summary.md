# Summary

source-controller turns remote content into artifacts, and every other Flux controller reads those artifacts instead of the remote. This module showed what an artifact is, how to choose what a source follows, how to give it access, and which source kinds exist.

## What you learned

An artifact is a `tar.gz` archive of one revision, stored by source-controller and served over HTTP inside the cluster. Its status has the URL, the revision, the digest, the size and the time of the last update. For Git, the revision is a reference name and a commit hash. The artifact is rebuilt from the remote after a restart. `flux get sources` shows the revision and the ready state of every source, `flux reconcile source` asks for a fetch now, and suspending a source freezes the content while suspending a Flux `Kustomization` stops the applying.

`spec.ref` decides what a `GitRepository` follows: a branch, a tag, a semantic version range, a commit or a full reference. Without `ref`, the branch is `master`. A tag or a commit stays fixed, a range takes new compatible releases, and a branch moves with each push. `spec.ignore` limits the files stored in the artifact, and `spec.include` adds the content of other sources.

Credentials live in a Secret in the namespace of the source and are named in `spec.secretRef`. HTTP sources use `username` and `password` or a token. SSH sources use `identity`, `identity.pub` and `known_hosts`, with a read-only deploy key. TLS sources add `ca.crt`, and optionally `tls.crt` and `tls.key`. The message in the `Ready` condition tells a missing Secret from a rejected credential.

Other kinds follow the same model. An `OCIRepository` pulls manifests stored in a container registry, created with `flux push artifact` and promoted with `flux tag artifact`. A `HelmRepository` points at a chart index or an OCI registry, and a `HelmRelease` makes helm-controller create the `HelmChart`. A `Bucket` reads files from object storage. The key facts to remember are these:

- The source revision answers the question what Flux deploys right now.
- Set exactly one reference, and name it explicitly.
- Credentials belong in a Secret in the namespace of the source, with the least access needed.
- Check the source first, then the sync that uses it.
- An OCI artifact is published once and promoted by tag, without a rebuild.

<!-- astrona:playground:destroy -->
