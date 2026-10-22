# Solution: Bootstrap Flux Into A Kind Cluster

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: `flux check` passes; the `flux-system` objects point at the right repository and path and are `Ready`; the bootstrap manifests are in Git; and the `podinfo` Kustomization comes from Git and has deployed podinfo.

## Step 1: Start the port-forward and check the cluster

`flux bootstrap` runs on your machine. It clones the repository, commits to it and pushes, so your machine must reach Gitea. Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Back in the first terminal, run the pre-installation checks:

```sh
flux check --pre
```

The checks look at the Flux CLI version and the Kubernetes version of the cluster, and they should all pass. Flux 2.9 needs Kubernetes 1.34.1 or later.

## Step 2: Bootstrap Flux

Run `flux bootstrap git` with the repository, branch, path and credentials from the task. `--token-auth=true` makes Flux use the user and password over HTTP instead of generating an SSH deploy key. `--allow-insecure-http=true` is needed because this Gitea has no TLS; never use it with a real Git server.

```sh
flux bootstrap git \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main \
  --path=clusters/kind \
  --username=gitops \
  --password=gitops-password \
  --token-auth=true \
  --allow-insecure-http=true
```

The command prints each step as it goes: it clones the repository, generates the component manifests, commits and pushes them, installs the controllers, creates the `flux-system` Secret with your credentials, applies the sync manifests, and waits until the `flux-system` Kustomization has reconciled. It ends with a line saying that all components are healthy. If it stops at the clone, check the port-forward first.

## Step 3: Verify the controllers, the CRDs and the flux-system objects

Check the components, the custom resource definitions (CRDs) and every Flux object in one go:

```sh
flux check
kubectl get crds | grep toolkit.fluxcd.io
flux get all -A
```

`flux check` reports each controller as healthy. The CRD list has one line per Flux kind, for example `gitrepositories.source.toolkit.fluxcd.io` and `kustomizations.kustomize.toolkit.fluxcd.io`. `flux get all -A` shows the `GitRepository` and the `Kustomization` named `flux-system`, both `Ready` `True`, with the revision `main@sha1:` followed by the commit that bootstrap pushed.

## Step 4: Commit the podinfo Kustomization

Clone the repository. The URL holds the lab-only password, so `git` does not ask for it; never do this with a real password.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
```

The folder `clusters/kind/flux-system` now holds the three files bootstrap wrote. Create the Flux `Kustomization` for podinfo next to that folder.

Save this as `clusters/kind/podinfo.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./apps/podinfo
  prune: true
  wait: true
  timeout: 3m
```

Commit and push it:

```sh
git add clusters/kind/podinfo.yaml
git commit -m "Deploy podinfo with Flux"
git push
```

## Step 5: Let Flux apply it and check podinfo

Flux would pick up the commit within a minute. Ask for it now instead:

```sh
flux reconcile kustomization flux-system --with-source
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

The `flux-system` Kustomization applies the new file, and the `podinfo` Kustomization appears and turns `Ready`. The `podinfo` Deployment shows `2/2` ready replicas. Both Kustomizations show the same revision, the commit you just pushed.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `flux install` and a `GitRepository` applied by hand | The controllers run, but nothing is in Git: Flux does not manage itself, and the grader finds no `clusters/kind/flux-system` |
| `kubectl apply -f clusters/kind/podinfo.yaml` | podinfo runs, but the object is not applied by the `flux-system` Kustomization, so the next change in Git is the only record of it |
| `--path=clusters/kind/flux-system` | Bootstrap writes its files one level deeper, and a file placed directly in `clusters/kind` is never applied |
| Putting `podinfo.yaml` under `apps/podinfo` | It is not under the synced path `clusters/kind`, so Flux never applies it |

## Common mistakes

- Running `flux bootstrap` without the port-forward. The clone fails, and the error names the host.
- Leaving out `--token-auth=true`. Bootstrap then tries to set up an SSH deploy key.
- Mixing up the two kinds of `Kustomization`. The file you commit is a Flux `Kustomization` object (`kustomize.toolkit.fluxcd.io/v1`); the Kustomize file `kustomization.yaml` under `apps/podinfo` only lists resources.
- Forgetting `git pull` before a second change. Bootstrap pushed commits after your clone.

## Practice on your own

- Run the same `flux bootstrap git` command a second time and compare `git log`. Bootstrap is idempotent, so it adds no commit when nothing changed.
- Delete the `podinfo` Deployment with `kubectl` and run `flux reconcile kustomization podinfo`. Watch Flux create it again.
- Remove `clusters/kind/podinfo.yaml` from Git and push. With `prune: true` on both Kustomizations, Flux removes the `podinfo` Kustomization and everything it applied.
