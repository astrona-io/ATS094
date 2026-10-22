# Overview: Bootstrap Flux From A Git Repository (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, runs a Git server with a prepared repository, puts the Flux command-line tool on your machine, and then waits. Flux itself is not installed: bootstrapping it is what you are here to try. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Flux CLI 2.9.6** on your PATH. Run `flux version --client` to see it. No Flux controllers run in the cluster yet.
- **Gitea**, a Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`. It runs over plain HTTP without TLS, which is only acceptable in a playground.
- The Gitea user `gitops` with the password `gitops-password`. These are lab-only credentials.
- The repository **`gitops/fleet`**, branch `main`:

  | Path | What it holds |
  | --- | --- |
  | `apps/podinfo/` | The podinfo application: a Namespace, a Deployment, a Service and the Kustomize file `kustomization.yaml` that lists them |
  | `clusters/kind/` | Only a `README.md`. This is the folder Flux will sync for this cluster |

- A `tester` pod in the namespace `gitea`, with `curl` and `jq`. You run `git` on your own machine.

## Reaching Gitea

Your machine reaches Gitea through a port-forward. Run it in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

The address is then `http://gitea.localtest.me:3000`. The public DNS name `gitea.localtest.me` resolves to `127.0.0.1`, so it reaches the port-forward. Inside the cluster, the playground makes the same name point at the Gitea Service, so Flux can use the same URL. If `git` says it cannot resolve the name, your router blocks DNS answers for `127.0.0.1`; add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `clone_fleet` clones `gitops/fleet` into the current folder with the lab-only password in the URL. `show_flux` prints every Flux object in the cluster and the custom resource definitions (CRDs) that Flux added.

```sh
clone_fleet() {
  git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
}
show_flux() {
  flux get all -A
  kubectl get crds | grep toolkit.fluxcd.io
}
```

Use them like this: `clone_fleet`, `show_flux`.

## Practice tasks

- Run `flux check --pre` before you install anything, and read which checks it runs.
- Bootstrap Flux with `flux bootstrap git` against `http://gitea.localtest.me:3000/gitops/fleet.git` with `--path=clusters/kind`, `--token-auth=true` and `--allow-insecure-http=true`. Then `git pull` your clone and list what bootstrap committed.
- Run the same bootstrap command again and compare `git log` before and after.
- Commit a Flux `Kustomization` for `./apps/podinfo` under `clusters/kind` and watch podinfo appear with `flux get kustomizations --watch`.
- Look at the keys of the `flux-system` Secret with `kubectl -n flux-system get secret flux-system -o jsonpath='{.data}' | jq 'keys'`, and think about what changes when the Git password changes.
