# Selecting A Tag With ImagePolicy

A registry has many tags. An `ImagePolicy` is the rule that picks exactly one of them. It refers to an `ImageRepository` and stores the selection in its status.

The commands below need the `ImageRepository` `podinfo` from the earlier part:

<!-- astrona:playground:renew -->

## Semantic versions

Most images use semantic versioning. The `semver` policy selects the highest tag that fits a range:

```sh
flux create image policy podinfo \
  --image-ref=podinfo \
  --select-semver='6.x'
flux get image policy
kubectl -n flux-system get imagepolicy podinfo -o jsonpath='{.status.latestRef.tag}{"\n"}'
```

The policy selects the newest 6.x tag. A range such as `>=6.0.0 <7.0.0` means the same, and `~6.5.0` accepts only patch releases of 6.5. A range that matches no tag leaves the policy without a selection, and its message says that no image was found. Pre-release tags such as `6.6.0-rc.1` are ignored unless the range allows them, for example `>=6.0.0-0`.

## Alphabetical and numerical

Not every image uses versions. For tags such as dates or build numbers, use `alphabetical` or `numerical`:

```yaml
spec:
  policy:
    numerical:
      order: asc
```

With `order: asc`, the last tag in the order wins, so the highest number or the latest date is chosen. For alphabetical order, `asc` selects the last value in the alphabet, which fits tags like `2026-11-03`. Alphabetical order sorts `9` after `10`, so use `numerical` for numbers.

## Filtering tags

Registries often hold tags for several branches. `filterTags` narrows the tags before the policy runs, and can extract part of a tag:

```yaml
spec:
  filterTags:
    pattern: '^main-[a-f0-9]+-(?P<ts>[0-9]+)$'
    extract: '$ts'
  policy:
    numerical:
      order: asc
```

Only tags from the branch `main` are used, and they are compared by the timestamp at the end. The selected image is still the full tag, not the extracted part.

## The result

The result is in `status.latestRef`, with the name, the tag and, when known, the digest. A marker in a manifest reads this value. The policy changes only its status. It does not change a Deployment, and it does not write to Git.

```sh
kubectl -n flux-system get imagepolicy podinfo -o jsonpath='{.status.latestRef}{"\n"}'
```

## Try it

1. Create the policy with `6.x` and read the tag it selects.
2. Change the range to `~6.5.0`. Which tag does it select now?
3. Change the range to `>=9.0.0` and read the `Ready` message. Put a working range back.
