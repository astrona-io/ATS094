# The Flux Vocabulary

The same few words appear in the output of `flux get`, in the status of every object and in the logs. This part defines each one and shows where to read it.

The commands below need the `GitRepository` `fleet` and the Flux `Kustomization` `namespaces` from the earlier part:

<!-- astrona:playground:renew -->

## Source, artifact and revision

A **source** is an object that tells Flux where desired state lives. The kinds are `GitRepository`, `OCIRepository`, `Bucket`, `HelmRepository` and `HelmChart`. A source does not change the cluster. It only fetches.

An **artifact** is the packaged result of a fetch: a `tar.gz` file of the repository contents, stored by source-controller and served inside the cluster. Other controllers download the artifact, not the repository.

A **revision** names one version of an artifact. For a `GitRepository` it has the form `main@sha1:<commit hash>`. For an `OCIRepository` it is a tag and a digest. The same revision always has the same content.

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{.status.artifact.revision}{"\n"}{.status.artifact.url}{"\n"}'
```

## Reconcile, apply and sync

To **reconcile** is to compare the desired state with the actual state and remove the difference. Every Flux object has its own reconcile loop. It runs when the interval has passed, when the object changes, when a source it uses has a new revision, or when you ask for it:

```sh
flux reconcile kustomization namespaces --with-source
```

To **apply** is the step inside a reconcile where kustomize-controller sends the objects to the Kubernetes API with server-side apply. People often say **sync** for the whole thing. The Flux documentation says reconcile, so this course does too.

## Prune, health check and inventory

**Prune** removes objects from the cluster when they have left Git. It is on when `spec.prune: true`.

A **health check** tests that the applied objects work. With `spec.wait: true`, the Flux `Kustomization` waits for all applied objects to be ready. With `spec.healthChecks`, it waits for the listed objects only. The `Ready` condition becomes true after the check passes.

The **inventory** is the list of objects that a Flux `Kustomization` applied. Pruning needs it, because it is the only way Flux knows what to remove:

```sh
kubectl -n flux-system get kustomization namespaces \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
flux tree kustomization namespaces
```

## Suspend and resume

**Suspend** stops the reconcile loop of one object: `flux suspend kustomization namespaces`. Nothing is applied or pruned until `flux resume kustomization namespaces`. Use it for a short, deliberate pause and always resume.

## Reading a status

Every Flux object has `status.conditions`. The condition `Ready` says whether the last reconcile worked, and its `message` says why. The field `status.lastAppliedRevision` shows the revision that was applied, and `status.lastAttemptedRevision` shows the revision that was tried last. When the two differ, the last attempt failed.

```sh
kubectl -n flux-system get kustomization namespaces \
  -o jsonpath='{.status.lastAppliedRevision}{"\n"}{.status.lastAttemptedRevision}{"\n"}'
flux get kustomizations
```

## Try it

1. Read the revision of the `GitRepository` and the revision that the Flux `Kustomization` applied. Why are they the same?
2. Run `flux suspend kustomization namespaces`, delete the namespace `staging`, wait a minute, and check the namespaces. Resume and observe.
3. List the inventory of `namespaces`. Which entry would disappear first if you removed `infrastructure/namespaces/staging.yaml` from Git with `prune: true`?
