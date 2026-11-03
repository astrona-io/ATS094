# Overview: Repository Structure And Cluster Layout (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and the Flux controllers, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`. They were installed with `flux install`, so no repository is connected yet: there is no `GitRepository` and no Flux `Kustomization`.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`. It uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.
- The private repository **`gitops/fleet`**, branch `main`:

  | Path | What it holds |
  | --- | --- |
  | `apps/base/podinfo/` | `deployment.yaml` (Deployment `podinfo`, 1 replica, port `9898`), `service.yaml`, and the Kustomize file that lists them. It has no namespace |
  | `apps/kind/` | The overlay for this cluster: the namespace `apps`, the base, and a patch for 2 replicas |
  | `infrastructure/controllers/` | The namespace `infra` and a custom resource definition for the kind `Widget` |
  | `infrastructure/configs/` | A `Widget` named `main`, which needs that definition |
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
  kubectl -n gitea exec deploy/tester -- curl -s http://podinfo.apps:9898
}
clone_fleet() {
  git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
}
```

Use them like this: `show_flux`, `podinfo_message`, `clone_fleet`.

## Practice tasks

- Create a Flux `Kustomization` for `./infrastructure/configs` before the one for `./infrastructure/controllers` and read the error in `flux events`.
- Create all three Flux `Kustomization` objects with `--depends-on` and watch the order in `flux get kustomizations`.
- Build the overlay with `kubectl kustomize fleet/apps/kind` and compare it with the base.
- Point the `apps` object at `./apps/base/podinfo` and find where the Deployment lands.
- Add a second folder `apps/staging` as a copy of `apps/kind` with 1 replica and a Flux `Kustomization` for it.
- Run `flux tree kustomization apps` and read the inventory.
