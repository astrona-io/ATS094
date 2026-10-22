# Overview: Reconcile A Cluster From Git With Flux (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and the Flux controllers, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`. They were installed with `flux install`, so no repository is connected yet: there is no `GitRepository` and no Flux `Kustomization`.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`. It uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.
- The private repository **`gitops/fleet`**, branch `main`:

  | Path | What it holds |
  | --- | --- |
  | `apps/podinfo/` | `namespace.yaml`, `deployment.yaml` (Deployment `podinfo`, 2 replicas, port `9898`), `service.yaml`, and the Kustomize file `kustomization.yaml` that lists them |
  | `clusters/kind/` | A short `README.md` only |

- A **`tester`** pod in the namespace `gitea`, with `curl` and `jq`. You run `git` on your own machine.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` both on your machine and inside the cluster. On your machine, that needs a port-forward running in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `show_flux` prints every Flux source and Flux `Kustomization` with its ready state and revision. `podinfo_message` sends one request to `podinfo` from the `tester` pod and prints the JSON answer, which includes the message and the version. `clone_fleet` clones the repository into the folder `fleet` (the port-forward must be running).

```sh
show_flux() {
  flux get sources git
  flux get kustomizations
}
podinfo_message() {
  kubectl -n gitea exec deploy/tester -- curl -s http://podinfo.podinfo:9898
}
clone_fleet() {
  git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
}
```

Use them like this: `show_flux`, `podinfo_message`, `clone_fleet`.

## Practice tasks

- Create the `GitRepository` `fleet` without `ref` and predict, before you run `show_flux`, why it never becomes ready.
- Point a Flux `Kustomization` at `./apps` instead of `./apps/podinfo` and read the error in `flux events --for Kustomization/<name>`.
- Change `PODINFO_UI_MESSAGE` in `apps/podinfo/deployment.yaml`, push, reconcile, and check the new message with `podinfo_message`.
- Run `kubectl -n podinfo delete service podinfo`, then `flux reconcile kustomization podinfo`, and explain where the Service came from.
- Set `prune: false`, remove a file from Git, reconcile, and find the object that stayed behind. Set `prune: true` again and predict whether Flux now deletes it.
- Suspend the Flux `Kustomization`, push a commit, and compare the revision in `flux get sources git` with the one in `flux get kustomizations`.
