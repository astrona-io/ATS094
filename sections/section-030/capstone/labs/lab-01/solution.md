# Solution: Recover A Cluster Whose Bootstrap Broke

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the `flux-system` `GitRepository` is `Ready` at the latest commit; the `flux-system` `Kustomization` syncs `./clusters/kind` and applied that commit; podinfo is fixed in Git and running; and Gitea still uses the rotated password.

## Step 1: See what is not Ready

Start with the whole picture:

```sh
flux get all -A
```

The `GitRepository` `flux-system` is not `Ready`. Its message says that source-controller could not fetch the repository because authentication failed. The `Kustomization` `flux-system` is not `Ready` either, and its message names a path that does not exist in the artifact. The `Kustomization` `podinfo` also fails on a missing path.

Three objects fail, so look at each one's own message before you change anything:

```sh
flux events --for GitRepository/flux-system
flux events --for Kustomization/flux-system
kubectl -n flux-system get kustomization flux-system -o jsonpath='{.spec.path}{"\n"}'
```

The `GitRepository` events repeat the authentication failure. The `flux-system` Kustomization syncs `./clusters/kind-old`. Git says `./clusters/kind`: someone patched the object in the cluster.

## Step 2: Understand why Flux cannot repair itself

Normally Flux puts a hand-patched `flux-system` Kustomization back, because the object is defined in `clusters/kind/flux-system/gotk-sync.yaml` and the `flux-system` Kustomization applies that file. Here that loop is broken twice. The Kustomization looks for `./clusters/kind-old`, which does not exist, so it never applies `gotk-sync.yaml` again. And source-controller cannot fetch new commits, because the `flux-system` Secret still holds the old password.

```mermaid
flowchart TB
    S["Secret flux-system"] -->|"old password"| G["GitRepository flux-system"]
    G -->|"no new artifact"| K["Kustomization flux-system"]
    K -->|"path kind-old"| X["nothing applied"]
    K -.->|"would apply"| Y["gotk-sync.yaml"]
```

The diagram shows why neither fault heals: the source cannot fetch with the old password, and the patched path stops the Kustomization from applying the file that would reset its own path.

## Step 3: Repair the credential and the sync path with bootstrap

Running `flux bootstrap git` again with the new password fixes both faults at once. Bootstrap is idempotent: it writes the new password into the `flux-system` Secret, and it applies the sync manifests again, which puts the path back to `./clusters/kind`. Start the port-forward in a second terminal first:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Then run bootstrap with the rotated password:

```sh
flux bootstrap git \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main \
  --path=clusters/kind \
  --username=gitops \
  --password=gitops-password-rotated \
  --token-auth=true \
  --allow-insecure-http=true
```

Bootstrap finds the component manifests in Git unchanged, so it pushes no new commit for them. It updates the Secret, applies the sync manifests and waits for the `flux-system` Kustomization. Check the two objects:

```sh
flux get sources git -A
flux get kustomizations -A
```

The `GitRepository` and the `Kustomization` `flux-system` are `Ready` at the latest commit, and the path is `./clusters/kind` again. Another valid repair is to replace only the Secret and patch the path back:

```sh
flux create secret git flux-system \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops \
  --password=gitops-password-rotated
kubectl -n flux-system patch kustomization flux-system --type merge \
  -p '{"spec":{"path":"./clusters/kind"}}'
flux reconcile kustomization flux-system --with-source
```

Either way, the `podinfo` Kustomization still fails. It now reads the latest commit, and that commit is the one with the wrong path.

## Step 4: Fix podinfo in Git

Clone the repository with the new password and look at the last change to `podinfo.yaml`:

```sh
git clone http://gitops:gitops-password-rotated@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
git log --oneline -- clusters/kind/podinfo.yaml
grep path: clusters/kind/podinfo.yaml
```

The last commit moved podinfo to `./apps/podinfo-v2`, and the repository has no such folder. Change the line to `path: ./apps/podinfo` in `clusters/kind/podinfo.yaml`, then commit and push:

```sh
git commit -am "Point podinfo back at apps/podinfo"
git push
```

## Step 5: Prove that Flux follows main again

Pull the new commit now instead of waiting a minute:

```sh
flux reconcile kustomization flux-system --with-source
flux reconcile kustomization podinfo
flux get all -A
kubectl -n podinfo get deployment podinfo
```

Every object is `Ready`, and both Kustomizations show the commit you just pushed. The `podinfo` Deployment has ready pods.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set the Gitea password back to `gitops-password` | The source recovers, but the rotation is undone; the grader rejects it |
| Patch only the path, not the Secret | The Kustomization finds `./clusters/kind` in the old artifact, but no new commit ever arrives |
| Replace only the Secret | The source recovers, but the `flux-system` Kustomization still looks for `./clusters/kind-old` and cannot reset itself |
| `kubectl patch` the podinfo path | The `flux-system` Kustomization applies `clusters/kind/podinfo.yaml` again and puts `./apps/podinfo-v2` back |
| `flux uninstall` and a fresh bootstrap | Breaks the constraint, and removes everything Flux applied while it runs |

## Common mistakes

- Fixing the podinfo path first. Until the credential works, the cluster does not even have the commit with the wrong path.
- Running bootstrap with the old password from your shell history.
- Cloning with the old password. Gitea answers `401` and `git` asks for a password.

## Practice on your own

- Rotate the password once more in Gitea with `kubectl -n gitea exec deploy/gitea -- gitea admin user change-password --username gitops --password <NEW> --must-change-password=false`, then repair Flux with `flux create secret git` alone.
- Read `clusters/kind/flux-system/gotk-sync.yaml` and find the two objects it defines. Note `prune: true` on the Kustomization: never point `flux-system` at a path that leaves out `flux-system/`, because Flux would then delete its own controllers.
