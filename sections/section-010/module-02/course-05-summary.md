# Summary

A Flux controller runs the same loop for every object it owns: it reads the object, compares the desired state with the current state, changes what differs, and writes the result into the status. This module followed that loop in kustomize-controller and showed how to read and shape it.

## What you learned

One run of a Flux `Kustomization` has a fixed order. The controller checks that the object is not suspended, checks its dependencies, downloads the artifact, builds the path, applies the result with server-side apply, prunes objects that left Git, waits for health, and writes the status and an event. A failure stops the run at its step, and the message says which one. The `Ready` condition is the summary, `Reconciling` shows work in progress, and `Stalled` says that the same input will not succeed. The `observedGeneration` must equal the `generation` before `Ready` describes the latest spec. The field `lastAttemptedRevision` shows the newest commit that was tried, and `lastAppliedRevision` shows the last one that worked.

Time is set by three fields. `interval` sets how often the folder is applied again after a success, and it also corrects drift. `retryInterval` sets the wait after a failure, and `timeout` limits one apply and health check. A new commit or a change of the object starts a run at once, and `flux reconcile` asks for a run with the annotation `reconcile.fluxcd.io/requestedAt`. An object is healthy when it passes the checks of `wait` or `healthChecks`. When `wait` is `true`, `healthChecks` is ignored, and a failed health check does not roll back what was applied.

Order between Flux `Kustomization` objects comes from `dependsOn`. A dependency must be `Ready` and up to date before the dependent object runs, and the check repeats on every run. A name that does not exist stops the dependent object before it builds anything. A dependency without a health check becomes ready too early, so the two features belong together.

Kubernetes tracks who set each field. kustomize-controller applies with server-side apply under the field manager `kustomize-controller`, and it takes back the fields that its manifests set. Fields it does not set stay under other managers. The setting `force` deletes and recreates an object when an immutable field changes, and it should stay off. The commands `flux trace` and `flux tree` follow the labels and the inventory between a resource and its Flux objects. The key facts to remember are these:

- A failed run stops at one step, and the status and events name it.
- `Ready` counts only when `observedGeneration` equals `generation`.
- `wait` overrides `healthChecks`.
- `dependsOn` waits for `Ready`, so give the dependency a health check.
- Flux corrects only the fields that are in the manifest.

<!-- astrona:playground:destroy -->
