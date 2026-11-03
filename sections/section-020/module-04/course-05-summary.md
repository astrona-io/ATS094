# Summary

helm-controller installs and upgrades Helm charts from a `HelmRelease`, so Helm releases follow the same declarative model as the rest of Flux. This module covered the objects, the values, the life cycle of a release and the tools around it.

## What you learned

A `HelmRepository` points source-controller at a chart repository, either an index over HTTP or an OCI registry. A `HelmRelease` names the chart, the version and the values, and Flux creates a `HelmChart` between them. The chart is packaged as an artifact that helm-controller reads. The release itself is stored as Secrets of the type `helm.sh/release.v1` in the storage namespace. Set `spec.releaseName` so that the names do not change with the target namespace.

Values come from the defaults of the chart, then from `spec.valuesFrom` in list order, then from `spec.values`, which wins. Maps are merged, and lists are replaced. Helm ignores keys that the chart does not read, so a release can be `Ready` and wrong.

An upgrade runs when the chart version, the values or the generation changes. `spec.timeout` limits how long an action waits. `install.remediation`, `upgrade.remediation` and `rollback` define retries and rollbacks, and `spec.test` runs Helm tests. The `Ready` message tells whether the failure is in the chart, in an action or in a resource.

`spec.driftDetection` corrects or reports changes made by hand, with `spec.driftDetection.ignore` for fields that other controllers own. `spec.dependsOn` orders releases. `spec.postRenderers` with `kustomize` patches the rendered manifests without a fork of the chart.

The key facts to remember are these:

- A `HelmRelease` is configuration. The chart's objects go to `targetNamespace`.
- Pin a version range, and name the release explicitly.
- Compare the running objects with the values you asked for.
- Choose retries and a timeout on purpose, and fix the cause after a rollback.
- Use drift detection when hand edits must not survive.

<!-- astrona:playground:destroy -->
