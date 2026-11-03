# Receivers And Webhooks

Flux checks a source on an interval. A short interval means many requests, and a long one means a delay. A `Receiver` removes the trade-off. It gives an outside system a URL to call, and the call starts a reconcile at once. The interval stays as a safety net.

The commands below need the `GitRepository` `fleet` from the earlier parts:

<!-- astrona:playground:renew -->

## The Receiver

A `Receiver` has a `type`, a Secret with a token, and a list of resources to reconcile:

```sh
kubectl -n flux-system create secret generic webhook-token \
  --from-literal=token="$(head -c 24 /dev/urandom | base64 | tr -d '/+=')"
```

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: fleet-push
  namespace: flux-system
spec:
  type: generic
  secretRef:
    name: webhook-token
  resources:
    - kind: GitRepository
      name: fleet
```

Types match the senders: `generic` and `generic-hmac` for any system, `github`, `gitlab`, `bitbucket`, `harbor`, `dockerhub`, `quay`, `gcr`, `nexus` and `acr` for Git hosts and registries. For `github`, `gitlab` and `bitbucket`, the `events` field limits which events count, for example `ping` and `push`. The `resources` can also name an `OCIRepository`, an `ImageRepository`, a `Bucket` or any other Flux source.

## The webhook path

Apply the Receiver and read its path:

```sh
kubectl -n flux-system get receiver fleet-push \
  -o jsonpath='{.status.webhookPath}{"\n"}'
```

The path starts with `/hook/` followed by a digest made from the token, the name and the namespace. Because of the digest, a path cannot be guessed, and a changed token produces a new path. The Receiver is ready when the path is set.

## Exposing the receiver

notification-controller serves webhooks through the Service `webhook-receiver` in `flux-system`. It is a ClusterIP Service, so reach it from outside through an Ingress or a Gateway, with TLS. For a test, use a port-forward:

```sh
kubectl -n flux-system port-forward svc/webhook-receiver 9292:80
```

In a second terminal, call the path with a POST:

```sh
curl -X POST "http://localhost:9292$(kubectl -n flux-system get receiver fleet-push -o jsonpath='{.status.webhookPath}')"
```

A successful call starts a reconcile of the `GitRepository`. Check that the `reconcile.fluxcd.io/requestedAt` annotation of the `GitRepository` changed:

```sh
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{.metadata.annotations.reconcile\.fluxcd\.io/requestedAt}{"\n"}'
```

In a Git host, set the same URL as a webhook for push events, with the same token as the secret where the type needs it.

## Security

- The token is the only secret. Keep it in a Secret, rotate it by changing the Secret, and update the webhook at the sender.
- Expose the receiver with TLS only. A webhook call carries no other authentication for the `generic` type.
- The call only requests a reconcile. It cannot change what Flux applies, so the worst case of a leaked path is extra reconciles.
- For senders that sign requests, use the matching type such as `github` or `generic-hmac`, so that the signature is checked.

## Receiver or interval

Use a Receiver for repositories and registries where a delay matters. Keep the interval at a few minutes anyway, because webhooks can fail, and the interval makes sure the cluster catches up.

## Try it

1. Create the Secret and the Receiver, and read `status.webhookPath`.
2. Port-forward the Service and call the path with `curl`. What did the annotation of the `GitRepository` do?
3. Change the token in the Secret and read the path again. Is it the same?
