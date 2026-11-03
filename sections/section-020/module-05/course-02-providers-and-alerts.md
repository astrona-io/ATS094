# Providers And Alerts

A `Provider` is a destination. An `Alert` is the rule that decides which events go there. Splitting them lets several alerts share one destination, and lets you change the destination in one place.

The commands below need the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` from the earlier part:

<!-- astrona:playground:renew -->

## The Provider

A `Provider` has a `type`, which says how to talk to the destination, and an `address`. Common types are `slack`, `discord`, `msteams`, `googlechat`, `telegram`, `matrix`, `alertmanager`, `pagerduty`, `opsgenie`, `datadog` and `generic` for any HTTP endpoint that accepts JSON. Create one for a generic endpoint:

```sh
flux create alert-provider team-webhook \
  --type=generic \
  --address=http://example.invalid/flux-events
flux get alert-providers
```

The address in this example is a placeholder, and the `Provider` becomes ready without a connection check. For a real service, the address often contains a secret, such as a Slack webhook URL. Put it into a Secret and refer to it:

```sh
kubectl -n flux-system create secret generic webhook-address \
  --from-literal=address=http://example.invalid/flux-events
```

```yaml
spec:
  type: generic
  secretRef:
    name: webhook-address
```

When `secretRef` is set, the key `address` of the Secret replaces `spec.address`. Other keys are `token`, `username`, `password` and `headers`, depending on the type. Keep secrets out of the `Provider`, because it is stored in Git.

## The Alert

An `Alert` names the `Provider` and the events to send:

```sh
flux create alert app-events \
  --provider-ref=team-webhook \
  --event-severity=info \
  --event-source=Kustomization/podinfo \
  --event-source=GitRepository/fleet
flux get alerts
```

The fields that matter:

| Field | Meaning |
| --- | --- |
| `providerRef.name` | The `Provider` in the same namespace |
| `eventSources` | A list of `kind`, `name` and optional `namespace`. The namespace defaults to the namespace of the `Alert` |
| `eventSeverity` | `info` sends everything, `error` sends only failures |
| `inclusionList` | Regular expressions on the message; only matching events are sent |
| `exclusionList` | Regular expressions on the message; matching events are dropped |
| `summary` | Text that is added to the message, for example the cluster name |

## Noise control

A cluster with many objects produces many informational events. Use `eventSeverity: error` for a chat channel that people read, and a second `Alert` with `info` for a log or an audit endpoint. Use `exclusionList` to drop messages that you know are harmless. Add a `summary` with the cluster name so that a message tells where it comes from.

The same `Alert` can list objects from several namespaces, but an `Alert` in one namespace can use event sources in another only when cross-namespace references are allowed on the controller. Platform teams often disable that, so that a tenant sees only its own events.

## Debugging an Alert

1. `flux get alerts` and `flux get alert-providers` show whether both are ready.
2. A message such as `provider not found` means `providerRef.name` is wrong.
3. A ready `Alert` that sends nothing means the filter selects nothing. Compare `eventSources` namespaces and names with `flux get`, and the severity with the events you expect.
4. `flux logs --kind=Alert` shows what notification-controller did.

## Try it

1. Create the `Provider` and the `Alert`, and run `flux get alerts`.
2. Change `providerRef.name` to a name that does not exist. What does the `Ready` message say? Put it back.
3. Set `eventSeverity: error` and explain which of the events from the earlier part would still match.

## Your mission: Route The Flux Events

You can now create a destination and a filter. The graded lab gives you an `Alert` that is not ready and would match nothing even after it was. Find out why, and fix it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-020-05
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/module-05/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-05/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-020-05
astrona start ats-094-playground-020-05
```
