# Install, Upgrade, Rollback And Remediation

helm-controller performs one of a few actions on each reconcile: install, upgrade, or nothing. What happens when an action fails is set by remediation rules. This part covers what triggers an upgrade, how failures are handled, and how to read the state.

The commands below need the `HelmRelease` `podinfo` from the earlier parts:

<!-- astrona:playground:renew -->

## What starts an upgrade

On every interval the controller compares the desired release with the installed one. It runs an upgrade when one of these changed: the chart version, the values, or the generation of the `HelmRelease`. It does nothing when they are the same. A new chart version that matches the range in `spec.chart.spec.version` also starts an upgrade. The interval alone does not upgrade a release.

Read the history of what happened:

```sh
flux get helmreleases
kubectl -n flux-system get helmrelease podinfo \
  -o jsonpath='{range .status.history[*]}{.version}{" "}{.chartVersion}{" "}{.status}{"\n"}{end}'
```

The history lists each release version with the chart version and the status. The list is part of the status of the `HelmRelease`.

## Timeout and waiting

An install or an upgrade waits for the resources to be ready, up to `spec.timeout`, which is 5 minutes by default. If the Deployment does not become ready in time, the action fails. Choose a timeout that fits the slowest startup of the chart. A too short timeout turns a slow start into a failed release.

## Remediation

Remediation says what to do when an install or an upgrade fails. It has its own number of retries for each action:

```yaml
spec:
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 3
      remediateLastFailure: true
  rollback:
    cleanupOnFail: true
```

With `retries: 3`, the controller tries again up to 3 times. After the retries are used, an upgrade failure triggers a rollback to the last successful release when remediation is set to do so. A negative number of retries means unlimited retries. With no `retries` set, a failed install or upgrade is not remediated: the release stays failed, and the controller tries again only because the interval runs again.

The first install is a special case. A failed install has no earlier release to go back to, so its remediation is to uninstall the failed attempt and try again. Without this, a half-installed release can block the next try.

## Rollback

A rollback restores the previous release version, with the previous chart and values. It is a new release version in the history, not a deletion. Use it when an upgrade made things worse and the retries are used. After a rollback the `HelmRelease` still holds the failing desired state, so fix the cause in Git. Otherwise the controller tries the same upgrade again.

## Helm tests

If a chart ships Helm tests, set `spec.test.enable: true` to run them after each install and upgrade. A failing test fails the action, and remediation applies. Many charts have no tests, and then the setting has no effect.

## Reading a failed release

Use this order:

1. `flux get helmreleases` shows the state.
2. The `Ready` message of the `HelmRelease` says which action failed.
3. If the message names the chart, read the `HelmChart` message (the earlier part).
4. If it names a resource, read the events and the status of that resource in the target namespace.
5. `flux logs --kind=HelmRelease --name=podinfo` shows the controller log lines for this release.

## Try it

1. Read the history of your release. How many versions does it have after your changes to the values?
2. Set the image tag in `spec.values` to a tag that does not exist, with `upgrade.remediation.retries: 1` and a `timeout` of `1m`. What happens to the release and to the running pods?
3. Fix the tag and confirm the release returns to `Ready`.

## Your mission: Fix The Helm Release

You can now read the status of a chart, a release and its values. The graded lab gives you a `HelmRelease` with a chart version that matches nothing and a values key the chart does not read. Find both and fix them, so that the application runs the way the values describe.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-020-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-020-04
astrona start ats-094-playground-020-04
```
