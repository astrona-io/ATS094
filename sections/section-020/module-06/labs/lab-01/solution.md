# Solution: Make The Image Policy Select And Update

Work the task yourself first. Running `astrona submit -c sections/section-020/module-06/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the `ImagePolicy` is `Ready` and selects a 6.x tag, the `ImageUpdateAutomation` pushed a commit, and the Deployment runs the selected tag.

## Step 1: Read the chain from the registry to Git

```sh
flux get image all
```

The `ImageRepository` is ready and has scanned tags. The `ImagePolicy` is not ready or has no latest image. The `ImageUpdateAutomation` has not changed anything. Read the policy:

```sh
kubectl -n flux-system get imagepolicy podinfo \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}{.spec.policy}{"\n"}'
```

The message says that no image matches the policy, and the range is `>=9.0.0`. No podinfo image has such a version.

## Step 2: Fix the range

```sh
kubectl -n flux-system patch imagepolicy podinfo --type=merge \
  -p '{"spec":{"policy":{"semver":{"range":"6.x"}}}}'
flux reconcile image repository podinfo
kubectl -n flux-system get imagepolicy podinfo \
  -o jsonpath='{.status.latestRef.tag}{"\n"}'
```

The policy now selects the newest 6.x tag.

## Step 3: Find why Git does not change

The automation runs, finds no markers, and makes no commit. Read its spec and status:

```sh
kubectl -n flux-system get imageupdateautomation fleet \
  -o jsonpath='{.spec.update}{"\n"}{.status.lastPushCommit}{"\n"}'
```

The `update.path` is `./clusters`, but the marker is in `apps/podinfo/deployment.yaml`. The automation only edits files under its path.

## Step 4: Fix the path

```sh
kubectl -n flux-system patch imageupdateautomation fleet --type=merge \
  -p '{"spec":{"update":{"path":"./apps/podinfo"}}}'
flux reconcile image update fleet
```

The controller changes the image line, commits it with the author `fluxcdbot` and pushes it to `main`. The status field `lastPushCommit` holds the commit.

## Step 5: Prove it

```sh
flux reconcile source git fleet
flux reconcile kustomization podinfo
kubectl -n flux-system get imageupdateautomation fleet -o jsonpath='{.status.lastPushCommit}{"\n"}'
kubectl -n podinfo get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The commit exists, and the Deployment runs the new tag.

## Why the wrong fixes fail

- Editing the image in Git or with `kubectl` changes the tag once, but leaves both image objects wrong, and the automation would not work for the next release.
- Fixing only the range leaves Git unchanged.
- Fixing only the path leaves nothing to write, because the policy selects no tag.
