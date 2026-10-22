# Summary

Flux is a set of separate controllers, and knowing which one owns a kind is the first step of every investigation. This module took Flux apart into those controllers, the tool you use to talk to them, and the components you can choose.

## What you learned

The GitOps Toolkit is the set of Flux controllers and the APIs they own. Each controller runs as its own Deployment in `flux-system` and watches the kinds of one API group. source-controller owns `source.toolkit.fluxcd.io` with `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart` and `Bucket`. kustomize-controller owns the Flux `Kustomization`, helm-controller owns `HelmRelease`, and notification-controller owns `Provider`, `Alert` and `Receiver`. A CustomResourceDefinition (CRD) makes each kind exist in the API server, but only the controller makes anything happen.

source-controller and kustomize-controller never call each other. source-controller fetches a revision, stores it as an artifact, a `tar.gz` file served inside the cluster, and records its address, revision and digest in `status.artifact` of the `GitRepository`. kustomize-controller reads that status, downloads the artifact, builds the path, and applies the result with server-side apply. Comparing the artifact's revision with the Flux `Kustomization`'s `lastAppliedRevision` tells you which side to look at. Every applied object carries labels that name the Flux `Kustomization` that owns it.

The `flux` command-line tool is a client of the Kubernetes API, like `kubectl`. `flux get` reads status, `flux events` reads events, `flux logs` filters the controller logs, and `flux tree` reads the inventory. `flux create --export` prints YAML without creating anything, `flux reconcile` only sets an annotation for the controller to act on, and `flux suspend` and `flux resume` change `spec.suspend`. A working `flux` command proves nothing about the controllers.

Flux installs four components by default. The image reflector and image automation controllers are optional and come with `--components-extra`, which adds to the default list, while `--components` replaces it. Applying an object whose CRD is missing fails at the API server; an object whose controller is missing is stored but never gets a condition. The key facts to remember are these:

- One controller owns each Flux kind; find the owner before you search.
- The artifact in `status.artifact` is the only link between source-controller and kustomize-controller.
- `flux` writes custom resources and annotations; the controllers do the work.
- Add optional controllers with `--components-extra`, then prove the result with `flux check`.

<!-- astrona:playground:destroy -->
