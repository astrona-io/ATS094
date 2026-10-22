# Summary

GitOps runs a cluster from a desired state kept in Git, and Flux is the software that keeps the cluster equal to it. This module showed the principles behind that and the Flux objects that make it work.

## What you learned

The four OpenGitOps principles define GitOps. The desired state is declarative, it is versioned and immutable, it is pulled automatically, and it is continuously reconciled. Pull-based delivery puts the agent inside the cluster: Flux needs only read access to Git, keeps its credentials in the cluster, and finds a manual change on its next run. A push-based pipeline needs write access to the cluster from outside and only acts when there is a commit.

Flux v2 is a graduated project of the Cloud Native Computing Foundation (CNCF). It is built as the GitOps Toolkit, a set of controllers in the namespace `flux-system`, each owning its own custom resources. The `flux` command-line tool only creates and reads those resources. `flux check` confirms that the controllers and their custom resource definitions are in place.

Two objects start the loop. A `GitRepository` makes source-controller clone one branch and store each commit as an artifact; its revision has the form `main@sha1:` followed by the commit hash. Credentials for a private repository come from a Secret with `username` and `password`, which `flux create secret git` creates. A Flux `Kustomization` makes kustomize-controller build one path of that artifact and apply it; it is a Flux object, not the Kustomize file `kustomization.yaml`. `flux get` shows whether each object is ready and which revision it holds, and `flux events` shows what happened and why. A change goes in as a commit, and `flux reconcile kustomization --with-source` makes the controllers run now instead of at the next interval.

Reconciliation also works against changes that do not come from Git. kustomize-controller applies the whole path again on every run, so a manual change is reverted. With `prune: true`, it deletes objects that it applied before and that have left Git, using the list in `.status.inventory`. Suspending a Flux `Kustomization` stops both, and the annotations `kustomize.toolkit.fluxcd.io/reconcile: disabled` and `kustomize.toolkit.fluxcd.io/prune: disabled` exclude a single object. The key facts to remember are these:

- source-controller fetches and stores artifacts; kustomize-controller builds and applies them. Check the source first, then the sync.
- Name the branch in a `GitRepository`; without `ref`, source-controller follows `master`.
- A manual change to an object that Flux manages lasts only until the next reconciliation.
- Without `prune: true`, an object removed from Git stays in the cluster outside Flux's view.

<!-- astrona:playground:destroy -->
