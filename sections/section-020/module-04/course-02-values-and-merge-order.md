# Values And Merge Order

A chart is a template. Its values decide what it produces. Flux gives you two ways to supply values: inline in the `HelmRelease`, and from a ConfigMap or Secret. Knowing how they combine saves you from the most common Helm mistake, a value that is silently ignored.

The commands below need the `HelmRelease` `podinfo` from the earlier part:

<!-- astrona:playground:renew -->

## Inline values

`spec.values` is a map written directly in the `HelmRelease`. It is passed to the chart like a values file:

```sh
kubectl -n flux-system patch helmrelease podinfo --type=merge \
  -p '{"spec":{"values":{"replicaCount":2,"ui":{"message":"hello from helm"}}}}'
flux reconcile helmrelease podinfo
kubectl -n podinfo get deployment podinfo
```

The Deployment runs 2 replicas after the upgrade. Inline values are best for a few values that belong with the release. Keep them in Git, and review them like code.

## Values from ConfigMaps and Secrets

`spec.valuesFrom` is a list of sources. Each entry has a `kind` (`ConfigMap` or `Secret`), a `name`, and optionally a `valuesKey` (default `values.yaml`) and a `targetPath`:

```yaml
spec:
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-common
      valuesKey: values.yaml
    - kind: Secret
      name: podinfo-secret
      valuesKey: ui-message
      targetPath: ui.message
```

Without `targetPath`, the value of the key is a complete values document in YAML. With `targetPath`, the value is written to that one path, which is useful for a single secret value such as a password. A Secret keeps the value out of Git, but anyone who can read the Secret can read it. If a source is missing, the release stops with an error. Set `optional: true` on the entry to continue without it.

## Which value wins

The controller builds the final values in this order. First the defaults of the chart. Then every entry of `valuesFrom`, in the order of the list, so a later entry overrides an earlier one. Last `spec.values`, which overrides everything before it. Maps are merged key by key. Lists are replaced as a whole, not merged.

When the result is not what you expect, read the sources in this order, and find the last one that sets the key.

## Keys the chart does not know

Helm does not check that your keys exist in the chart. If you write `replicas: 2` and the chart reads `replicaCount`, the install succeeds, the key does nothing, and the Deployment runs the default number of replicas. The release is `Ready` and wrong. To avoid this:

- Read the chart's own values, with `helm show values podinfo --repo https://stefanprodan.github.io/podinfo`, or in the chart documentation.
- After a change, compare the running objects with what you asked for.
- If the chart ships a values schema (`values.schema.json`), Helm checks the values against it and fails on a type or a missing required field. A schema does not always reject extra keys.

## See what the controller used

The values that the controller applied are part of the release:

```sh
kubectl -n flux-system get helmrelease podinfo -o jsonpath='{.spec.values}{"\n"}'
kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.spec.replicas}{" "}{.metadata.labels.helm\.sh/chart}{"\n"}'
```

The first command prints the inline values. The second prints the effective replicas and the chart label of the running object. With the `helm` command available, `helm get values podinfo -n podinfo` prints the user-supplied values of the installed release.

## Try it

1. Set `replicaCount: 2` inline and confirm that the Deployment runs 2 replicas.
2. Add the wrong key `replicas: 3`. Does the release stay `Ready`, and how many replicas run?
3. Move the message into a ConfigMap with `valuesFrom` and `targetPath: ui.message`. Which value wins if you also keep it inline?
