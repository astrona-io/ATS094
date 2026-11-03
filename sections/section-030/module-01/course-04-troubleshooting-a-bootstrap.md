# Troubleshooting A Bootstrap

A bootstrap can fail while it runs, or finish and leave a cluster that does not follow Git. This part lists the failures in the order they appear, and how to tell them apart.

The commands below need the cluster from the earlier part, bootstrapped with `clusters/kind` as the path:

<!-- astrona:playground:renew -->

## Failures while it runs

`flux bootstrap` stops at the first step that fails and says which one. Match the step to the cause:

- **It cannot clone the repository.** The address, the credential, or the connection is wrong. Check the URL, check that the port-forward runs, and try `git clone` with the same address and user.
- **It cannot push.** The credential can read but not write, or the branch is protected. Bootstrap pushes commits to the branch, so it needs write access. Use a branch without protection, or a token that is allowed to push.
- **The repository is empty and has no branch.** `flux bootstrap git` needs at least one commit on the branch. Create the repository with an initial commit.
- **It waits and times out after the install.** The controllers started, but the `flux-system` Flux `Kustomization` is not ready. Open a second terminal and run `flux get all -A` while it waits.

Running the command again is safe. It is idempotent, so a half-finished bootstrap is completed by repeating it.

## Failures after it finishes

Start with the three checks from the earlier part:

```sh
flux check
flux get sources git -A
flux get kustomizations -A
```

Then read the case that matches.

**The controllers are not all running.** `flux check` names the missing one. Look at the pods with `kubectl -n flux-system get pods` and at the events for an image that cannot be pulled.

**The source `flux-system` is not ready.** Read its message. A credential that no longer works is the common cause. Compare the Secret with the one you expect:

```sh
kubectl -n flux-system get secret flux-system -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n flux-system get gitrepository flux-system -o jsonpath='{.spec.url}{"\n"}'
```

**The Flux `Kustomization` `flux-system` is not ready, and the source is.** The path is wrong, or a file in the synced folder is invalid. A single invalid file in `clusters/kind` stops the whole Flux `Kustomization` because Flux applies the folder as one unit. Build it on your machine:

```sh
git pull
kubectl kustomize clusters/kind/flux-system
```

**A new application never appears.** The Flux `Kustomization` that applies it is outside the synced path, or the folder has a `kustomization.yaml` that does not list it. Check the path of the `flux-system` Flux `Kustomization` and the files in that folder.

**Flux stopped following Git after a change that was pushed.** The change broke the Flux `Kustomization` `flux-system` itself, for example by removing the `GitRepository` from the folder. Flux cannot repair itself when its own manifests are broken. Repair it from your machine, then push the fix:

```sh
flux bootstrap git --url=... --branch=main --path=clusters/kind ...
```

Bootstrap writes the sync manifests again and applies them.

## A checklist after every bootstrap

1. `flux check` ends with all checks passed.
2. The `GitRepository` `flux-system` shows the latest commit.
3. The Flux `Kustomization` `flux-system` shows the same commit and is ready.
4. `git log` shows the commits that bootstrap pushed.
5. A test commit with a new object appears in the cluster after `flux reconcile kustomization flux-system --with-source`.

## Try it

1. Run `flux bootstrap git` a second time with the same flags. What does it change in Git?
2. Add an invalid file to `clusters/kind`, push, and read the message of the Flux `Kustomization` `flux-system`. Fix it.
3. Wrong credential: change the password in the Secret `flux-system` and watch the source. Put it back with `flux create secret git`.
