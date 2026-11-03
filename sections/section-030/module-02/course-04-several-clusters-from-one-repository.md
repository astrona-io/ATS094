# Several Clusters From One Repository

The layout from the earlier parts has a folder `clusters/kind`. A second cluster is a second folder. This part shows what the clusters share, what they change, and how a single value can differ between them.

The commands below need the Flux `Kustomization` objects `infrastructure-controllers`, `infrastructure-configs` and `apps` from the earlier part:

<!-- astrona:playground:renew -->

## What is shared and what differs

Clusters usually share the application and part of the infrastructure, and differ in a few values: a replica count, a domain name, a size. The layout keeps the shared part in `base` folders and puts differences in one overlay or one variable per cluster.

```text
apps/
  base/podinfo/
  staging/        overlay for staging clusters
  production/     overlay for production clusters
clusters/
  staging/        entry point of the staging cluster
  production/     entry point of the production cluster
```

Each cluster follows its own folder. Its `flux-system` objects, created by bootstrap with `--path=clusters/production`, point at that folder, and the folder's Flux `Kustomization` objects point at `./apps/production`. A cluster never reads the entry point of another.

## Variables with postBuild

An overlay is a good fit when many values change. For one or two values, a **variable** is simpler. `spec.postBuild.substitute` replaces `${name}` in the built manifests, and `spec.postBuild.substituteFrom` reads the values from a ConfigMap or a Secret:

```sh
kubectl -n flux-system create configmap cluster-vars \
  --from-literal=cluster_name=kind \
  --from-literal=replicas=2
```

In a manifest in Git:

```yaml
metadata:
  labels:
    cluster: ${cluster_name}
spec:
  replicas: ${replicas}
```

In the Flux `Kustomization`:

```yaml
spec:
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-vars
```

A value without a variable stays as written. A variable that is missing is replaced by an empty string, which usually breaks the manifest. Use a default, `${replicas:=1}`, for values that may be missing. A `$` that is not meant as a variable, such as in a shell script in a ConfigMap, must be written `$$`.

The `ConfigMap` itself is part of the cluster, not the repository. That keeps the manifests identical in all clusters, and each cluster has its own values.

## Patches in the Flux Kustomization

A Flux `Kustomization` can also patch what it applies, with `spec.patches`. That lets the entry point of a cluster change a shared folder without a new overlay:

```yaml
spec:
  path: ./apps/base/podinfo
  patches:
    - target:
        kind: Deployment
        name: podinfo
      patch: |-
        - op: replace
          path: /spec/replicas
          value: 3
```

Use an overlay folder when the change is large or shared by many clusters. Use `patches` for one small change that belongs to one cluster.

## Secrets in a shared repository

Never commit a plain Secret to a repository that several clusters read. Use the Flux support for SOPS decryption (`spec.decryption`) or a controller that creates Secrets from a store. The key to decrypt is then the one thing that differs per cluster.

## Try it

1. Create the ConfigMap `cluster-vars`, add `postBuild.substituteFrom` to `apps` and use `${replicas}` in a copy of the overlay. What does `kubectl -n apps get deployment podinfo` show after a reconcile?
2. Remove the key `replicas` from the ConfigMap, reconcile, and read the `Ready` message.
3. Write a default with `${replicas:=1}` and repeat step 2.
