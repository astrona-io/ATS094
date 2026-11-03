# Promotion And Rollback

With environments in place, two questions remain. How does a change get from staging to production? And how do you undo a change that should not have gone out? In GitOps both answers are Git operations.

The commands below need the two Flux `Kustomization` objects `staging` and `production` from the earlier part, and a clone of the repository in the folder `fleet`:

<!-- astrona:playground:renew -->

## Promotion

**Promotion** means that production receives a change that staging already ran. In a folder-per-environment repository, a change that lives only in an overlay affects only that environment. A change in the base affects both. That gives two ways to promote:

- Change a value in the staging overlay first. Check it in the cluster. Then make the same change in the production overlay, in a second commit.
- Change a value in the base only after it has been tested. Both environments receive it at once, so use this for changes that are safe everywhere.

Example of the first way. Change the message of staging, push, and watch it arrive:

```sh
cd fleet
sed -i.bak 's/"staging"/"staging v2"/' apps/podinfo/overlays/staging/kustomization.yaml
rm apps/podinfo/overlays/staging/kustomization.yaml.bak
git add -A
git -c user.name=student -c user.email=student@example.com commit -m "Staging: new message"
git push
flux reconcile kustomization staging --with-source
kubectl -n staging get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].env[0].value}{"\n"}'
```

Production still shows `production`, because its overlay did not change. When staging has proven the change, repeat it in the production overlay.

A common mistake is to promote by editing the Deployment in the cluster. Flux replaces it at the next reconcile, and Git still holds the old value.

## Rollback

To **roll back** is to return to a state that worked. In GitOps you do not roll back the cluster. You change Git, and Flux follows.

```sh
git revert --no-edit HEAD
git push
flux reconcile kustomization staging --with-source
```

`git revert` creates a new commit that undoes an earlier one. The history stays complete, and a pull-based agent only ever moves forward through it. Compare this to `git reset --hard` followed by a forced push, which rewrites history. Flux can handle it, but the record of what was once running is gone.

Check what Flux applied:

```sh
flux get kustomizations
git log --oneline -3
```

The revision shown by `flux get kustomizations` is the new revert commit.

## What can go wrong

- The Flux `Kustomization` is suspended. Nothing is applied until `flux resume`. Look at `flux get kustomizations` for `True` in the suspended column.
- The change breaks the build of the overlay. The Flux `Kustomization` keeps the last applied state and reports the error. Use `kubectl kustomize` before you push.
- The change is correct but the health check fails, for example a wrong image tag. With `wait: true`, the `Kustomization` is not ready, and the new pods do not replace the old ones until they become ready. Revert the commit.

## Try it

1. Promote a new message from staging to production in two commits. After each push, check both namespaces.
2. Revert the commit that changed production. What does `git log --oneline` show?
3. Suspend `production`, push a change to its overlay, and reconcile `staging`. Which environment changed? Resume `production` and watch it catch up.
