# Summary

notification-controller sends Flux events out and takes webhooks in. This module covered the events, the objects that route them, and the objects that receive calls.

## What you learned

Flux controllers record events on the objects they own and send them to notification-controller. `flux events` and `kubectl events` read them. An event has a severity of `info` or `error`, a reason and a message.

A `Provider` is a destination with a `type` and an `address` or a Secret. An `Alert` selects events by `eventSources` and `eventSeverity`, and sends them to the `Provider` in `providerRef`. `inclusionList`, `exclusionList` and `summary` shape the messages. An `Alert` that selects nothing is silent, so check names, namespaces and severity first.

Git providers such as `github`, `gitlab` and `gitea` write a commit status for the revision that a Flux `Kustomization` applied. The status is only as meaningful as the health checks of that Flux `Kustomization`.

A `Receiver` gives an outside system a hidden URL under `/hook/`. A call to it requests a reconcile of the listed resources. The Service `webhook-receiver` must be exposed with TLS for outside senders.

The key facts to remember are these:

- Events are the source, the `Alert` is the filter, and the `Provider` is the destination.
- A silent Alert is usually a filter that matches nothing.
- Keep addresses and tokens in Secrets.
- Commit statuses close the loop back to Git.
- A Receiver speeds up reconciles; the interval stays as a safety net.

<!-- astrona:playground:destroy -->
