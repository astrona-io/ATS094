# Scanning A Registry With ImageRepository

The first link in the chain is a list of tags. An `ImageRepository` asks a registry for every tag of one image, at an interval, and stores the result in its status. Nothing is changed yet.

The commands below need the Flux controllers, including the two image controllers, in the namespace `flux-system`:

<!-- astrona:playground:renew -->

## Create the scan

```sh
flux create image repository podinfo \
  --image=ghcr.io/stefanprodan/podinfo \
  --interval=1m
flux get image repository
```

The image is written without a tag. The status shows the number of tags found and the time of the last scan. The newest tags are listed in the status:

```sh
kubectl -n flux-system get imagerepository podinfo \
  -o jsonpath='{.status.lastScanResult.tagCount}{"\n"}{.status.lastScanResult.latestTags}{"\n"}'
```

The list `latestTags` is a short sample of the tags. The controller keeps all tags it found, so a policy selects from all of them, not only from the sample.

## Registry credentials

A public image needs no credentials. A private one needs a Secret of the type `kubernetes.io/dockerconfigjson` in the same namespace, named in `spec.secretRef`:

```sh
flux create secret oci regcred \
  --url=ghcr.io --username=USER --password=TOKEN
```

```yaml
spec:
  image: ghcr.io/example/private-app
  secretRef:
    name: regcred
```

The token needs the permission to read packages and nothing more. On AWS, Azure and Google Cloud, set `spec.provider` to `aws`, `azure` or `gcp` instead of a Secret, and the controller uses the identity of the cluster. A registry with a private certificate authority takes `spec.certSecretRef`.

## What a scan costs

Every scan calls the registry. A short interval on many images can reach rate limits, and a registry that limits anonymous pulls slows the chain down. Choose an interval that fits how fast you want a new tag to arrive: one minute is useful for a test, ten minutes or more for a production cluster. The `exclusionList` field removes tags that match a regular expression before they are stored, for example signature tags.

## Reading a failed scan

```sh
kubectl -n flux-system get imagerepository podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

A wrong image name, a wrong Secret or a missing network path shows here, and the tag count stays at zero. Fix the scan before you look at the policy.

## Try it

1. Create the `ImageRepository` and read the tag count and the time of the last scan.
2. Change the image to a name that does not exist. What does the `Ready` message say? Change it back.
3. Run `flux reconcile image repository podinfo` and compare the scan time before and after.
