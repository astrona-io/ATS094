# Summary

The words of GitOps are exact. Desired state is in Git, actual state is in the cluster, and reconciliation moves the second toward the first. A repository that holds a base and one overlay per environment, with one Flux `Kustomization` per overlay, runs several environments from one source of truth.

The four OpenGitOps principles are declarative, versioned and immutable, pulled automatically, and continuously reconciled. Pull-based delivery keeps cluster credentials in the cluster and corrects drift. Push-based delivery runs only when a pipeline runs.

The Flux terms are these. A source fetches and produces an artifact. A revision names one version of it. Reconcile compares desired and actual state, apply sends the objects to the API, prune removes objects that left Git, a health check waits for readiness, and the inventory lists what was applied.

Each environment has its own `path`, its own `targetNamespace`, and a `dependsOn` for shared infrastructure such as namespaces. A wrong path or a wrong namespace still reports success, so check the cluster as well as the status.

Promotion is a commit in the next environment's overlay. Rollback is a `git revert` followed by a push.

The key facts to remember are these:

- Git is the desired state. The cluster is the actual state. Drift is the difference.
- Flux is pull-based and corrects drift on every reconcile.
- A `Ready` Flux `Kustomization` proves it applied something, not that it applied the right thing.
- Use folders for environments, and one Flux `Kustomization` per folder.
- Change Git to promote or roll back. Never edit the cluster.

<!-- astrona:playground:destroy -->
