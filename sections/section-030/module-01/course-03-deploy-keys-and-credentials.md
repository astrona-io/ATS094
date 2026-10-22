# Deploy Keys, Tokens And The flux-system Secret

A bootstrapped cluster depends on one thing that is not in Git: the credential source-controller uses to read the repository. When that credential stops working, for example after a password rotation, the cluster quietly stops following Git. This part shows where the credential lives, the two kinds Flux uses, and how to replace one without reinstalling anything.

## Where the credential lives

Bootstrap stored the credential in the Secret `flux-system` in the namespace `flux-system`, and the `GitRepository` `flux-system` names that Secret in `spec.secretRef`. Source-controller reads the Secret every time it fetches the repository. Check both ends in your playground. The commands read only the names of the keys in the Secret, never the values:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get gitrepository flux-system -o jsonpath='{.spec.secretRef.name}{"\n"}'
kubectl -n flux-system get secret flux-system -o jsonpath='{.data}' | jq 'keys'
```

The first command prints `flux-system`. The second lists the keys `password` and `username`, because you bootstrapped with `--token-auth=true`. The Secret is not in Git: bootstrap created it directly in the cluster, and `gotk-sync.yaml` only refers to it by name. That is on purpose. A credential committed to Git would be readable by everyone who can read the repository.

## Token authentication and SSH authentication

Flux reads Git in one of two ways, and the keys of the Secret show which one a `GitRepository` uses:

| | Token or password (HTTPS) | SSH |
| --- | --- | --- |
| Bootstrap flag | `--token-auth=true` with `--username` and `--password` | The default: no `--token-auth` |
| URL in the `GitRepository` | `https://...` (or `http://...` in this lab only) | `ssh://git@...` |
| Keys in the Secret `flux-system` | `username`, `password` | `identity` (private key), `identity.pub` (public key), `known_hosts` (the server's host key) |
| What gives access | A personal access token or password of a Git user | A deploy key registered on the repository |
| Scope of the access | Everything that user may reach | One repository |

With SSH, bootstrap generates a key pair, by default ECDSA with the P-384 curve, and stores the private key in the Secret. The public key must be registered on the repository as a deploy key. A **deploy key** is an SSH key that gives access to exactly one repository, either read-only or read-write. Provider commands such as `flux bootstrap github` register it through the provider's API; with `flux bootstrap git`, you add it yourself. `known_hosts` lets source-controller check that it talks to the real Git server.

A deploy key is the better choice for a real cluster, because a leaked key opens one repository, not a whole user account. Source-controller only reads, so a read-only deploy key is enough for syncing. Write access is only needed by a component that commits to Git, such as image-automation-controller when it writes new image tags back. Gitea in your playground has SSH turned off, so this playground uses token authentication.

## Rotating a credential

Passwords and tokens expire or get rotated. When that happens, source-controller can no longer fetch the repository, and the `GitRepository` stops being `Ready`. The cluster does not break at once: kustomize-controller keeps applying the last artifact it has. But no new commit reaches the cluster, and that can go unnoticed for days.

The fix is to put the new credential in the Secret. `flux create secret git` creates or updates a Git credential Secret. Run it first with `--export`, which prints the Secret as YAML instead of changing the cluster, so you can check what it would write:

```sh
flux create secret git flux-system \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password \
  --export
```

The output is a Secret named `flux-system` in the namespace `flux-system` that holds the user and the password. Here the password has not changed, so updating the Secret with the same values is safe to practise. Run the command again without `--export`, then make source-controller fetch with the stored credential:

```sh
flux create secret git flux-system \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password
flux reconcile source git flux-system
flux get sources git -A
```

The `GitRepository` `flux-system` stays `Ready`, at the same revision as before. After a real rotation you would run the same commands with the new password, and the `GitRepository` would turn `Ready` again at the newest commit.

Running `flux bootstrap git` again with the new credential is the other way to rotate. It updates the Secret in the same way, and it also applies the sync manifests again, which repairs a `flux-system` `GitRepository` or `Kustomization` that someone changed by hand. Bootstrap is idempotent, so it changes nothing else.

You now know where Flux keeps its Git credential, what the two kinds look like, and how to replace one. The question to keep in mind for any real cluster is who will notice when the credential stops working, because a stale cluster looks healthy until you check the source.

## Common pitfalls

> [!WARNING]
> - **Committing the Secret to Git.** The credential belongs in the cluster only. Bootstrap creates it there; `gotk-sync.yaml` refers to it by name.
> - **Reading only the Kustomizations.** After a credential failure, the Kustomizations stay `Ready` on the last artifact. Check the `GitRepository` and its revision too.
> - **Giving Flux a read-write deploy key it does not need.** Syncing only reads. Grant write access only to a component that commits to Git.
> - **Changing the password in Git first and in Flux much later.** Every minute in between, the source fails. Rotate both in one change window.
