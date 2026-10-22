# What flux bootstrap Does

Before you run a command that writes to your Git repository and installs software in your cluster, you should know exactly what it will do. This part takes `flux bootstrap` apart: the steps it runs, the files it commits, and the objects it creates. It also explains why a cluster built this way manages its own Flux installation.

## Two ways to install Flux

Flux has two installation commands, and they leave a cluster in very different states. `flux install` applies the Flux controllers to the cluster and stops there. It is meant for development and testing. `flux bootstrap` installs the same controllers, but it also commits their manifests to a Git repository and connects Flux to that repository.

| | `flux install` | `flux bootstrap` |
| --- | --- | --- |
| Installs the controllers | Yes | Yes |
| Writes anything to Git | No | Yes, under `<path>/flux-system` |
| Creates a `GitRepository` and `Kustomization` | No | Yes, both named `flux-system` |
| Flux upgrades itself from Git | No | Yes |
| Meant for | Development and tests | Every cluster you want to run from Git |

The rest of this part is about the right-hand column, because that is what makes a cluster reproducible. A cluster built with `flux install` can be turned into a bootstrapped one later, by running bootstrap against it.

## The steps of a bootstrap

A bootstrap is a fixed series of steps. The Flux CLI runs all of them on your machine, so your machine must reach both the Git server and the cluster:

1. **Clone the repository.** The CLI clones the repository and branch you name. Provider commands, such as `flux bootstrap github`, can first create the repository through the provider's API.
2. **Write the component manifests.** The CLI generates the manifests for the Flux controllers of its own version and writes them to `<path>/flux-system/gotk-components.yaml`.
3. **Install the components.** The CLI applies those manifests to the cluster: the `flux-system` namespace, the custom resource definitions (CRDs) and the controllers. A CRD is a schema that adds a new resource kind, such as `GitRepository`, to the Kubernetes API.
4. **Store the credential.** The CLI creates the Secret `flux-system` in the namespace `flux-system`. It holds what source-controller needs to read the repository: a user and password, or an SSH key.
5. **Write the sync manifests.** The CLI writes `<path>/flux-system/gotk-sync.yaml`, with a `GitRepository` and a Flux `Kustomization` object, both named `flux-system`, plus a Kustomize file `kustomization.yaml` that lists the two manifest files. It commits and pushes them.
6. **Apply the sync manifests and wait.** The CLI applies `gotk-sync.yaml` and waits until the `flux-system` Kustomization has reconciled the path.

```mermaid
sequenceDiagram
    participant C as flux CLI
    participant G as Git server
    participant K as cluster
    C->>G: clone
    C->>G: push gotk-components.yaml
    C->>K: apply controllers and CRDs
    C->>K: create Secret flux-system
    C->>G: push gotk-sync.yaml
    C->>K: apply gotk-sync.yaml
    K->>G: fetch with the Secret
```

The diagram shows the CLI writing to Git and to the cluster in turn; in the last step the controllers in the cluster fetch the repository themselves, without the CLI.

## The three files bootstrap writes

Bootstrap writes exactly three files, all in the folder `flux-system` under the path you choose with `--path`. Each has one job:

| File | What it holds |
| --- | --- |
| `gotk-components.yaml` | The namespace, CRDs, controllers, service accounts and network policies of Flux, for one Flux version |
| `gotk-sync.yaml` | The `GitRepository` `flux-system` (repository URL, branch, interval, the Secret to use) and the Flux `Kustomization` `flux-system` (which path of that source to apply) |
| `kustomization.yaml` | A Kustomize file that lists the two files above, so they are applied together |

The name `kustomization.yaml` and the kind `Kustomization` are two different things, which confuses almost everyone at first. The Kustomize file `kustomization.yaml` is a plain list of manifests for the `kustomize` tool. The Flux `Kustomization` object, from the API `kustomize.toolkit.fluxcd.io/v1`, is a custom resource that tells kustomize-controller what to apply from a source.

## Flux manages itself

The `flux-system` Kustomization applies the path you passed to `--path`, for example `./clusters/kind`. That path contains the folder `flux-system`, which contains `gotk-components.yaml` and `gotk-sync.yaml`. So Flux applies its own controllers and its own sync objects from Git, on every reconciliation.

That loop has two useful results. First, upgrading Flux is a commit: a newer `gotk-components.yaml` in Git means newer controllers in the cluster. Second, running bootstrap again is safe. Bootstrap is idempotent: when the manifests in Git already match, it changes nothing, and when the CLI is newer, it commits the newer components, which is an upgrade.

## One bootstrap command per kind of Git server

The steps are the same everywhere, but the first one differs. A provider command talks to the provider's API, so it can create the repository and register a deploy key for you. The generic `flux bootstrap git` works with any Git server, but the repository must already exist and the credential is yours to provide.

| Command | Git server | What the provider API adds |
| --- | --- | --- |
| `flux bootstrap github` | GitHub and GitHub Enterprise | Creates the repository, registers a deploy key |
| `flux bootstrap gitlab` | GitLab | Creates the project, registers a deploy key |
| `flux bootstrap gitea` | Gitea | Creates the repository, registers a deploy key |
| `flux bootstrap bitbucket-server` | Bitbucket Server and Data Center | Creates the repository, registers a deploy key |
| `flux bootstrap git` | Any Git server over SSH or HTTPS | Nothing: the repository must exist |

Your playground uses `flux bootstrap git` against Gitea, because it shows every step with nothing done behind the scenes. Before you run it, check the cluster and look at the repository it will write to.

<!-- astrona:playground:renew -->

`flux check --pre` runs only the checks that come before an installation: it checks the Flux CLI and the Kubernetes version of the cluster. Flux 2.9 needs Kubernetes 1.34.1 or later.

```sh
flux check --pre
```

Every check should pass. Now look at what the repository holds. Your machine reaches Gitea through a port-forward, so start it in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Back in the first terminal, clone the repository. The public DNS name `gitea.localtest.me` resolves to `127.0.0.1`, which is where the port-forward listens. If `git` cannot resolve it, add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts`. The URL holds the lab-only password, so `git` does not ask for it.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
ls -R fleet/clusters fleet/apps
```

The folder `clusters/kind` holds only a `README.md`, and `apps/podinfo` holds the four podinfo files. There is no `flux-system` folder yet: bootstrap writes it.

You now know what bootstrap will do before it does it. It writes the Flux components and the sync objects into `clusters/kind/flux-system`, installs the controllers, stores a credential in the Secret `flux-system`, and from then on Flux applies its own manifests from Git. The open question is what that looks like on a real cluster, and how you prove that it worked.

## Common pitfalls

> [!WARNING]
> - **Treating `flux install` as a GitOps installation.** It installs controllers and nothing else. No repository describes them, and Flux does not upgrade itself.
> - **Mixing up `kustomization.yaml` and `Kustomization`.** The first is a Kustomize file that lists manifests; the second is a Flux object that tells kustomize-controller what to apply.
> - **Expecting `flux bootstrap git` to create the repository.** Only provider commands talk to an API. The generic command needs an existing repository.
> - **Editing `gotk-components.yaml` by hand.** Bootstrap regenerates it. Change Flux settings with bootstrap flags or with patches in the Kustomize file `kustomization.yaml` next to it.
