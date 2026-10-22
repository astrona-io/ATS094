# Bootstrap Flux From A Git Repository

A cluster where someone ran `flux install` has Flux, but it is not run from Git. The controllers run, yet no repository records their version or settings, and nothing tells Flux which repository to follow. Rebuild that cluster tomorrow, and you rebuild it from memory.

`flux bootstrap` is the command that fixes this. It installs the Flux controllers, commits their manifests to a Git repository, and creates the objects that make Flux reconcile that repository, including its own manifests. After bootstrap, Flux manages itself: an upgrade, a new setting and a new application are all commits.

Keep one sentence in mind: **bootstrap writes Flux into Git first, and then lets Flux apply Git.** Everything in this module follows from it, including why running bootstrap twice is safe and why a changed Git password stops the whole cluster from following Git.

The module has three parts. **What flux bootstrap Does** walks through the steps of a bootstrap, the three files it writes and the bootstrap command for each kind of Git server. **Bootstrapping A Kind Cluster And Verifying It** runs `flux bootstrap git` against the Git server in your playground, checks the result, and deploys an application through Git. A graded lab follows it. **Deploy Keys, Tokens And The flux-system Secret** explains the credential Flux uses to read its repository and how to replace it.

## Learning objectives

After this module you can:

- Explain the difference between `flux install` and `flux bootstrap`.
- List the steps `flux bootstrap` takes and the files it writes under `<path>/flux-system`.
- Explain why a bootstrapped Flux manages itself and why running bootstrap again is safe.
- Choose the bootstrap command for GitHub, GitLab, Gitea, Bitbucket Server or any other Git server.
- Bootstrap Flux with `flux bootstrap git` and verify the controllers, the CRDs and the `flux-system` objects.
- Deploy an application by committing a Flux `Kustomization` object next to `flux-system`.
- Describe what the `flux-system` Secret holds for token and SSH authentication, and replace a rotated credential.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Secrets, custom resources and the commands `kubectl get` and `kubectl apply`. You also need Git basics: clone, commit and push. It helps to know what a Flux `GitRepository` and a Flux `Kustomization` are. A `GitRepository` tells Flux which repository and branch to fetch, and a Flux `Kustomization` object tells Flux which folder of that source to apply to the cluster.

Your playground is a single-node `kind` cluster. **Flux is not installed in it.** The **Flux CLI 2.9.6** is on your PATH, and a Git server runs inside the cluster:

| What | Where |
| --- | --- |
| Gitea, the Git server | Namespace `gitea`, Service `gitea-http`, port `3000`, plain HTTP without TLS |
| The repository `gitops/fleet` | `apps/podinfo` holds the podinfo application; `clusters/kind` is empty apart from a `README.md` |
| Git user | `gitops`, password `gitops-password` (lab-only credentials) |

Your machine reaches Gitea at `http://gitea.localtest.me:3000` through a port-forward, and the playground makes the same name work inside the cluster, so Flux and your machine use one URL. The parts show the port-forward command when you first need it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
