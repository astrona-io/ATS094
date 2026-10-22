# GitOps Principles And Pull-Based Delivery

Before you connect Flux to a repository, you need to know what it promises to do and what it does not. This part explains the four principles that define GitOps, compares two ways of getting a change into a cluster, and then shows you the Flux controllers that are already running in your playground. At the end you look at the repository Flux will read.

## The four OpenGitOps principles

GitOps means running a system from a desired state kept in Git, which software agents pull and apply continuously. The desired state is the full description of what should run: every Deployment, Service and setting. OpenGitOps, a working group of the Cloud Native Computing Foundation (CNCF), wrote down four principles that a GitOps system follows:

| Principle | What it means | In your playground |
| --- | --- | --- |
| **Declarative** | The desired state says *what* should exist, not the steps to create it | `apps/podinfo/deployment.yaml` says "2 replicas of `podinfo`", not "run `kubectl scale`" |
| **Versioned and immutable** | The desired state is stored so that every version is kept and cannot be changed afterwards | Every change is a Git commit with its own hash; old commits stay in the history |
| **Pulled automatically** | Software agents fetch the desired state from the source themselves | The Flux controllers fetch `gitops/fleet` from Gitea |
| **Continuously reconciled** | The agents keep comparing the live state with the desired state and fix any difference | Flux applies the folder again at a fixed interval, even if Git did not change |

The table shows the principles as a list, but they work as a chain. Because the state is declarative, an agent can compare it with the cluster. Because it is versioned, you can see who changed what and go back. The last two principles are the ones that need software, and they are the subject of the rest of this part.

## Push-based and pull-based delivery

There are two ways to get the desired state into a cluster, and the difference is where the work runs. In **push-based delivery**, a pipeline outside the cluster, for example a continuous integration (CI) job, runs `kubectl apply` against the cluster after each commit. In **pull-based delivery**, an agent inside the cluster fetches the desired state and applies it itself.

```mermaid
flowchart TB
    subgraph push["Push-based"]
        G1["Git"] -->|"commit triggers"| P["CI pipeline"]
        P -->|"kubectl apply"| C1["cluster"]
    end
    subgraph pull["Pull-based"]
        G2["Git"] -->|"fetch"| F["Flux in cluster"]
        F -->|"apply"| C2["cluster"]
    end
```

The diagram shows the two directions: on the left the pipeline pushes into the cluster, on the right Flux pulls from Git and applies inside the cluster.

The direction changes three things. The first is credentials. A push-based pipeline needs credentials that can change the cluster, stored outside the cluster. Flux keeps its credentials inside the cluster and needs only read access to Git. The second is drift. A pipeline runs only when there is a commit, so a manual change stays until the next deployment. Flux runs on a timer and finds the manual change on its next run. The third is what happens when something fails: a failed pipeline leaves the cluster half changed until someone runs it again, while Flux simply tries again at the next interval.

## Flux and the GitOps Toolkit

Flux v2 is a graduated project of the CNCF, which means the CNCF considers it stable and widely used in production. Flux is not one program. It is a set of Kubernetes controllers called the **GitOps Toolkit**. A controller is a program in the cluster that watches custom resources of some kinds and reconciles them. Each controller owns its own custom resources and does one job: one fetches sources, one applies them, one installs Helm charts, one sends notifications. The command-line tool `flux` only creates and reads those resources; the controllers do the work.

Your playground already runs the controllers. They were installed with `flux install`, which installs Flux without connecting it to any repository. First ask the `flux` tool to check them:

<!-- astrona:playground:renew -->

```sh
flux check
```

`flux check` prints the version of the `flux` tool and of each controller, and a line for each custom resource definition it found. A custom resource definition (CRD) is a schema that adds a new resource kind, such as `GitRepository`, to the Kubernetes API. The last line says that all checks passed. If a controller is not ready, `flux check` names it, so this is the first command to run when Flux seems to do nothing.

The controllers are ordinary Deployments in the namespace `flux-system`, and the CRDs are ordinary cluster objects. List both:

```sh
kubectl -n flux-system get deployments
kubectl get crds | grep toolkit.fluxcd.io
```

You see four Deployments: `source-controller`, `kustomize-controller`, `helm-controller` and `notification-controller`. The CRD list has names such as `gitrepositories.source.toolkit.fluxcd.io` and `kustomizations.kustomize.toolkit.fluxcd.io`. The part of the name after the first dot is the API group, and it tells you which controller owns the kind: `source.toolkit.fluxcd.io` belongs to source-controller, `kustomize.toolkit.fluxcd.io` to kustomize-controller.

## The repository Flux will read

The controllers are running, but no object tells them about a repository yet, so they have nothing to do. Look at the repository yourself before you hand it to Flux. Start a port-forward to Gitea in a **second terminal** and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

The name `gitea.localtest.me` resolves to `127.0.0.1` on your machine, so the port-forward makes Gitea answer at `http://gitea.localtest.me:3000`. If `git clone` below says it cannot resolve the host, your router blocks DNS answers that point at `127.0.0.1`; add the line `127.0.0.1 gitea.localtest.me` to `/etc/hosts` and try again.

Back in your first terminal, clone the repository. The user name and password are in the URL so that Git does not ask for them; this is lab-only practice, never do it with real credentials:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
ls apps/podinfo
cat apps/podinfo/kustomization.yaml
```

The folder `apps/podinfo` holds four files: `namespace.yaml`, `deployment.yaml`, `service.yaml` and `kustomization.yaml`. The last one is a Kustomize file. It lists the other three under `resources:`, and Kustomize builds them into one set of objects. The folder `clusters/kind` holds only a short `README.md` for now.

This is the whole desired state for `podinfo`: declarative, and versioned in Git. You now know the four principles, the difference between pushing and pulling, and which controllers will do the pulling. The open question is how to tell those controllers to read this folder, which is what a `GitRepository` and a Flux `Kustomization` do.

## Common pitfalls

> [!WARNING]
> - **Thinking the `flux` tool does the deployment.** The controllers in `flux-system` do all the work. The tool only creates and reads their objects, so closing your terminal changes nothing.
> - **Calling a CI job that runs `kubectl apply` "GitOps".** Git is the source, but nothing pulls or reconciles. A manual change stays until the next pipeline run.
> - **Forgetting the port-forward.** `git clone` and `git push` on your machine fail while it is not running. The controllers in the cluster do not need it.
> - **Mixing up the two `kustomization` files.** `apps/podinfo/kustomization.yaml` is a Kustomize file. The Flux `Kustomization` is an object in the cluster that you create in the next step.
