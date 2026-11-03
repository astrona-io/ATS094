# Helm Controller And Releases

Many applications are shipped as Helm charts. helm-controller installs and upgrades those charts from inside the cluster, so Helm releases follow the same rule as everything else in Flux: the desired state is in a Kubernetes object, and a controller makes the cluster match it. You do not run `helm install` yourself.

Three objects work together. A `HelmRepository` (owned by source-controller) points at a chart repository. A `HelmChart` (created for you) is the chart fetched from it. A `HelmRelease` (owned by helm-controller) says which chart, which version and which values to install. The controller uses the Helm library directly, so the `helm` command is not needed in the cluster.

Keep one sentence in mind: **a Helm chart ignores values it does not know, so a release can be Ready and still be wrong.** Always compare the result with what you asked for.

The module has four parts. The first part covers the three objects and where a release is stored. The second part covers values and their merge order. The third part covers installs, upgrades, rollbacks and remediation, and a graded lab follows it. The fourth part covers drift detection, ordering and post-renderers.

## Learning objectives

After this module you can:

- Create a `HelmRepository` and a `HelmRelease`, and name the `HelmChart` that connects them.
- Find where Helm stores a release and read it with `flux get helmreleases`.
- Set chart values with `spec.values` and `spec.valuesFrom`, and explain which source wins.
- Explain what triggers an upgrade, and configure retries, rollback and remediation.
- Turn on drift detection and order releases with `dependsOn`.
- Change a chart's output with a post-renderer, without forking the chart.

## Before you start

You need the basics of Flux: `flux get`, `flux reconcile`, and the idea of a source and a sync. You need to know what a Helm chart is: a package of templates and default values.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` tool on your machine, and the Flux controllers in the namespace `flux-system`, installed with `flux install`, including helm-controller |
| `gitea` (namespace `gitea`) | An in-cluster Git server. The user `gitops` (password `gitops-password`, lab-only) owns the repository `gitops/fleet` |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

The chart repository is `https://stefanprodan.github.io/podinfo`, so the parts need outbound internet access. The optional `helm` command is useful for reading a chart, but every task works with `flux` and `kubectl` alone.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
