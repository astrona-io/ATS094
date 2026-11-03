# Summary

A repository layout is a set of folders and the Flux `Kustomization` objects that point at them. A monorepo is the simplest start. A repository per team or per environment adds access control and costs copying and more objects to manage.

For one cluster, use three top-level folders: `apps` for what users run, `infrastructure` for what the applications need, and `clusters` for the entry point. Split `infrastructure` into `controllers` and `configs`, so that custom resource definitions exist before the objects that use them.

`spec.dependsOn` orders Flux `Kustomization` objects, and `spec.wait` or `spec.healthChecks` make a dependency mean that the applied objects work. When several objects are not ready, read them in dependency order. The first one holds the real cause.

For several clusters, share a `base`, and change values with an overlay folder, with `postBuild` variables from a ConfigMap, or with `patches` in the Flux `Kustomization`. Keep secrets out of the repository in plain form.

The key facts to remember are these:

- A Flux `Kustomization` applies one folder of one source.
- Infrastructure is applied before applications, and controllers before configuration.
- `dependsOn` reads the Ready condition, and `wait: true` makes Ready mean healthy.
- The first object in a chain that is not ready holds the cause.
- A cluster follows its own folder under `clusters` and never another cluster's.

<!-- astrona:playground:destroy -->
