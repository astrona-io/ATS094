# Bootstrapping A Kind Cluster And Verifying It

Knowing the steps of a bootstrap is not the same as having a cluster that follows Git. This part runs `flux bootstrap git` against the Gitea server in your playground, checks every piece it created, and then deploys podinfo the GitOps way: with a commit, not with `kubectl apply`.

## Running flux bootstrap git

`flux bootstrap git` runs on your machine and needs to reach the Git server, so the port-forward to Gitea must be running. If you closed it, start it again in a second terminal and leave it there:

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

The bootstrap command takes the repository, the branch, the path for this cluster and the credential. Each flag answers one question:

| Flag | Value here | What it decides |
| --- | --- | --- |
| `--url` | `http://gitea.localtest.me:3000/gitops/fleet.git` | The repository; the same URL ends up in the `GitRepository` |
| `--branch` | `main` | The branch Flux follows (`main` is the default) |
| `--path` | `clusters/kind` | The folder Flux applies for this cluster; bootstrap writes into `clusters/kind/flux-system` |
| `--username`, `--password` | `gitops`, `gitops-password` | The credential stored in the Secret `flux-system` |
| `--token-auth=true` | | Use the user and password over HTTP or HTTPS, instead of generating an SSH key |
| `--allow-insecure-http=true` | | Allow plain HTTP. Needed only because this Gitea has no TLS; a real Git server uses HTTPS or SSH |

The URL works on your machine and inside the cluster. On your machine, `gitea.localtest.me` resolves to `127.0.0.1` and reaches the port-forward. Inside the cluster, the playground added a rule to CoreDNS, the cluster's DNS server, that sends the same name to the Gitea Service. Run the bootstrap:

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

The command asks you to confirm, then prints one line per step, in the order the steps were described before: it clones the repository, generates and pushes the component manifests, installs the controllers, creates the Secret, pushes and applies the sync manifests, and waits for the reconciliation. It ends by saying that all components are healthy. The first run takes a minute or two, because the cluster pulls the controller images.

## Verifying the installation

A finished bootstrap is a claim, so check it from three sides: the controllers, the APIs they add, and the objects that connect them to Git. Run the three checks together:

```sh
flux check
kubectl get crds | grep toolkit.fluxcd.io
flux get all -A
```

`flux check` reports the version of each controller and that it is healthy: source-controller, kustomize-controller, helm-controller and notification-controller. The CRD list has one line per Flux kind, such as `gitrepositories.source.toolkit.fluxcd.io`, `kustomizations.kustomize.toolkit.fluxcd.io` and `helmreleases.helm.toolkit.fluxcd.io`. `flux get all -A` shows the `GitRepository` `flux-system` and the `Kustomization` `flux-system`, both `Ready` `True`, with a revision like `main@sha1:` followed by a commit hash.

That commit hash belongs to the commit bootstrap pushed. Pull it into your clone and look:

```sh
cd fleet
git pull
git log --oneline
ls clusters/kind/flux-system
```

The log shows bootstrap's commits on top of the seeded ones, and `clusters/kind/flux-system` holds `gotk-components.yaml`, `gotk-sync.yaml` and `kustomization.yaml`. Open `gotk-sync.yaml` in an editor. The `GitRepository` names the URL, the branch `main`, an interval of one minute and the Secret `flux-system`. The `Kustomization` points at that `GitRepository` with the path `./clusters/kind` and has `prune: true`.

## Deploying an application through Git

Flux now applies everything under `clusters/kind`. To deploy podinfo, add a Flux `Kustomization` object there that points at `./apps/podinfo` in the same repository. It reuses the `GitRepository` `flux-system`, so podinfo needs no second source or credential.

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

`prune: true` lets kustomize-controller delete what it applied once the file is gone from Git. `wait: true` makes the Kustomization `Ready` only when the Deployment is ready, not just applied. Commit and push the file:

```sh
git add clusters/kind/podinfo.yaml
git commit -m "Deploy podinfo with Flux"
git push
```

Flux checks the repository every minute. Ask it to fetch now, then check the result:

```sh
flux reconcile kustomization flux-system --with-source
flux get kustomizations
kubectl -n podinfo get deployment podinfo
```

`--with-source` makes source-controller fetch the new commit before kustomize-controller applies it. The `flux-system` Kustomization applies `podinfo.yaml`, the new `podinfo` Kustomization applies the podinfo manifests, and both show the commit you pushed. The Deployment shows two ready replicas.

You bootstrapped a cluster from Git, proved it from the controllers to the objects, and deployed an application without touching it with `kubectl apply`. What is left is the credential that holds this together: the Secret `flux-system`, and what happens when it stops working.

## Common pitfalls

> [!WARNING]
> - **No port-forward.** `flux bootstrap` and `git` run on your machine. Without the port-forward, the clone fails and the error names `gitea.localtest.me`.
> - **Choosing `--path` too deep.** With `--path=clusters/kind/flux-system`, bootstrap writes into `clusters/kind/flux-system/flux-system`, and files you put in `clusters/kind` are never applied.
> - **Committing the application outside the synced path.** A Flux `Kustomization` saved under `apps/` is not under `clusters/kind`, so nothing applies it.
> - **Forgetting `git pull`.** Bootstrap pushed commits after your clone. Pull before you commit, or the push is rejected.

## Your mission: Bootstrap Flux Into A Kind Cluster

You can now bootstrap Flux from a repository, verify it, and deploy an application through Git. The graded lab gives you a fresh cluster with no Flux and the same repository, and asks you to bootstrap it with the path `clusters/kind` and get podinfo running from a commit.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-030-01
astrona start ats-094-playground-030-01
```
