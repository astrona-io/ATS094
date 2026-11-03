# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** The Helm controller

## Scenario

A colleague wants the `podinfo` application installed from its Helm chart with Flux. The chart repository is `https://stefanprodan.github.io/podinfo`. The values ask for 2 replicas and the message `hello from helm`. The `HelmRepository` and the `HelmRelease` named `podinfo` in the namespace `flux-system` apply without an error, but the application does not run as intended.

## Your task

1. Find out why the `HelmRelease` `podinfo` is not ready. There is more than one cause, and the second one only shows after you fix the first.
2. Fix the `HelmRelease` so that it installs a 6.x version of the chart, and so that the application runs 2 replicas.
3. Confirm that the Deployment `podinfo` in the namespace `podinfo` has 2 ready replicas and the message `hello from helm` in its environment.

## Constraints

- **Flux must install the chart.** Do not install it with `helm install` or apply the rendered files with `kubectl`.
- Keep the names `podinfo` for the `HelmRepository`, the `HelmRelease` and the release, the target namespace `podinfo`, and the message `hello from helm`.
- Do not suspend any object and do not delete the `HelmRelease`.

## Done when

- `flux get helmreleases` shows `podinfo` as `Ready`.
- The Deployment `podinfo` in the namespace `podinfo` comes from a 6.x version of the chart, runs 2 ready replicas, and has `PODINFO_UI_MESSAGE` set to `hello from helm`.
- The values of the `HelmRelease` use the key `replicaCount` and do not contain the key `replicas`.
