# GitRepository References, Include And Ignore

A repository holds many versions of the same files. Which one should a cluster run? A development cluster may follow the newest commit, and a production cluster may only run a tagged release. The field `spec.ref` of a `GitRepository` decides this, and `spec.ignore` and `spec.include` decide which files end up in the artifact.

The commands below need your clone of `gitops/fleet` and the port-forward to Gitea in a second terminal, and a `GitRepository` named `fleet` that follows the branch `main`:

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

## The reference options

`spec.ref` takes one of these:

| Field | What source-controller follows |
| --- | --- |
| `branch` | The newest commit of a branch. The default is `master` when `ref` is left out |
| `tag` | One tag. The revision is the tag name and the commit it points to |
| `semver` | The highest tag that matches a semantic version range, for example `">=1.0.0 <2.0.0"` |
| `commit` | One exact commit hash |
| `name` | A full Git reference such as `refs/heads/main` or `refs/pull/420/head` |

Set only one of them. If you set several, Flux uses the most specific one and ignores the others, which hides mistakes.

## Follow a tag

A branch moves with every push, and a tag names one commit. Create a tag in your clone and push it:

```sh
git tag v1.0.0
git push origin v1.0.0
```

Point the source at the tag:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"branch":null,"tag":"v1.0.0"}}}'
flux reconcile source git fleet
flux get sources git
```

In a merge patch, `null` removes a field, so `branch` disappears and `tag` is the only reference. The revision now has the form `v1.0.0@sha1:` followed by the commit hash. Commits pushed to `main` after the tag do not change the artifact. A release is promoted by moving the tag in the object, or by creating a newer tag and using a range.

## Follow a version range

Following one tag by name means editing the cluster for every release. A semantic version range lets the cluster take new releases by itself. Change the reference:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"tag":null,"semver":">=1.0.0 <2.0.0"}}}'
```

source-controller lists the tags, keeps those that parse as semantic versions, and selects the highest one in the range. Push a tag `v1.1.0` and reconcile: the revision changes to `v1.1.0@sha1:...`. A tag `v2.0.0` stays out of the range, so a major version never reaches the cluster without a change of the object. The range is also a safety rule.

## Follow one commit

For a precise rollback or for a build you want to pin, use the hash:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"semver":null,"commit":"<commit-hash>"}}}'
```

Replace `<commit-hash>` with a hash from `git log`. The source will not move until you change the object, even if the branch gets new commits.

Go back to the branch before you continue:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"ref":{"commit":null,"branch":"main"}}}'
flux reconcile source git fleet
```

## Choose which files are stored: ignore

By default the artifact holds all files of the commit, except the Git metadata. In a repository with many folders, this wastes space and triggers work for every change, even in folders the sync does not use. `spec.ignore` takes patterns in the `.gitignore` format. The common form first excludes everything and then lets some paths back in:

```yaml
spec:
  ignore: |
    # exclude all
    /*
    # include only the apps folder
    !/apps
```

With this setting the artifact holds only `apps`. If you point a Flux `Kustomization` at another path, the build fails, because that folder is not in the artifact. A `.sourceignore` file in the repository has the same format and is read as well. Use `spec.ignore` when you cannot change the repository.

## Combine repositories: include

A source can also pull in other sources. `spec.include` copies the content of another `GitRepository` into a folder of this artifact:

```yaml
spec:
  include:
    - repository:
        name: shared-config
      fromPath: base
      toPath: shared
```

The artifact of the including source then has the folder `shared`, filled from the folder `base` of the artifact of `shared-config`. This lets one sync use files from two repositories, such as application code and shared settings, while the Flux `Kustomization` still has a single `sourceRef`.

## Read what changed

After each change of `ref`, check the artifact with the same command:

```sh
flux get sources git
kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact.revision}{"\n"}'
```

The revision tells you in one line whether the reference does what you meant. If it still shows the old name, the object has not been fetched again yet, so run `flux reconcile source git fleet`.

You now know how to choose what a source follows and what it stores. The next problem is access: a private repository only answers to the right credentials.

## Common pitfalls

> [!WARNING]
> - **Leaving out `ref`.** The default branch is `master`. A repository with only `main` gives a source that never becomes ready.
> - **Setting several references.** Flux picks one, and the others stay in the object as noise. Remove what you do not use.
> - **A tag with no `v` where the range expects one.** Tags that are not valid semantic versions are skipped silently. Check with `git tag --list`.
> - **Ignoring too much.** If `ignore` removes the folder that a Flux `Kustomization` uses, the sync fails with a path error and the source stays `Ready`.
