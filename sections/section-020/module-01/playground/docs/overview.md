# Overview: Find Your Way Around The GitOps Toolkit (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, runs a Git server, installs Flux, and sets up one application that Flux already applies from Git. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The Flux command-line tool `flux`, version **2.9.6**, on your PATH.
- **Flux 2.9.6** in the namespace `flux-system`, installed with `flux install`. It runs the four default controllers: `source-controller`, `kustomize-controller`, `helm-controller` and `notification-controller`. A controller is a program in the cluster that watches custom resources of some kinds and changes the cluster to match them.
- **Gitea**, a Git server, in the namespace `gitea`. It holds the repository `gitops/fleet` with the application `podinfo` under `apps/podinfo`. The user `gitops` with the password `gitops-password` can read and write it. These are lab-only credentials, and Gitea runs over plain HTTP; a real Git server uses HTTPS or SSH.
- Two Flux objects in `flux-system` that are already working:

  | Object | What it does |
  | --- | --- |
  | `GitRepository` `fleet` | source-controller fetches `main` of `gitops/fleet` every minute and stores it as an artifact. It reads the user name and password from the Secret `fleet-auth` |
  | Flux `Kustomization` `podinfo` | kustomize-controller applies `./apps/podinfo` from that artifact every minute, prunes objects removed from Git, and waits for them to be ready |

- The application `podinfo` in the namespace `podinfo`: a Deployment with two pods and a Service on port `9898`.
- A `tester` pod in the namespace `gitea`, with `curl`, `jq` and `git`.

The Flux `Kustomization` object is not the same thing as the Kustomize file `kustomization.yaml` in `apps/podinfo`. The Flux object tells kustomize-controller which path to build; the file tells Kustomize which YAML files belong together.

## Reaching Git from your machine

The Git address everywhere is `http://gitea.localtest.me:3000/gitops/fleet.git`. The name `gitea.localtest.me` resolves to `127.0.0.1` on your machine, and inside the cluster a DNS rewrite sends it to the Gitea Service. On your machine, Gitea answers only while a port-forward runs. Start it in a second terminal and leave it open:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

If `git` cannot resolve `gitea.localtest.me`, your router blocks DNS answers that point at `127.0.0.1`. Add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts` and try again.

## Helpers

Paste these once in each new terminal. `show_flux` prints every Flux object and whether it is ready. `show_artifact` prints the artifact source-controller stored for `fleet`. `flux_controllers` lists the controller Deployments and their ready replicas.

```sh
show_flux() {
  flux get all --all-namespaces
}
show_artifact() {
  kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.artifact}' | jq
}
flux_controllers() {
  kubectl -n flux-system get deployments
}
```

Use them like this: `show_flux`, `show_artifact`, `flux_controllers`.

## Practice tasks

- List the CustomResourceDefinitions (CRDs) Flux installed with `kubectl get crds | grep toolkit.fluxcd.io`. Group them by API group and name the controller that owns each group.
- Run `flux tree kustomization podinfo` and compare the list with `kubectl -n podinfo get all`. Note which objects the tree shows and which it leaves out.
- Run `flux create kustomization demo --source=GitRepository/fleet --path=./apps/podinfo --interval=5m --export` and compare the YAML with `kubectl -n flux-system get kustomization podinfo -o yaml`. Nothing is created: `--export` only prints.
- Suspend the Flux Kustomization with `flux suspend kustomization podinfo`, scale the Deployment with `kubectl -n podinfo scale deployment podinfo --replicas=4`, and run `flux reconcile kustomization podinfo`. Predict what happens. Then run `flux resume kustomization podinfo` and watch the replica count.
- Scale `source-controller` to zero with `kubectl -n flux-system scale deployment source-controller --replicas=0`, run `flux check`, and read what it reports. Scale it back to `1` afterwards.
- Follow the controller logs with `flux logs --all-namespaces --follow`, clone the repository on your machine, change `PODINFO_UI_MESSAGE` in `apps/podinfo/deployment.yaml`, push, and watch the two controllers react.
