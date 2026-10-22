# Find Your Way Around The GitOps Toolkit

A Flux `Kustomization` stays `Ready False`, and the message says it cannot find an artifact. Is the problem in Git, in the Flux `Kustomization`, or in a controller? You cannot tell until you know which part of Flux does which job. This module gives you that map.

Flux is built from the **GitOps Toolkit** (GOTK): a set of controllers and the APIs they own. A controller is a program in the cluster that watches custom resources of some kinds and changes the cluster to match them. source-controller fetches sources such as Git repositories. kustomize-controller applies what source-controller fetched. Each one works on its own, and they talk to each other only through custom resources and files called artifacts.

Keep one sentence in mind: **every Flux feature is a custom resource, and one controller owns each kind.** The `flux` command-line tool does not do the work. It reads and writes those custom resources, and the controllers in the cluster act on them.

The module has three parts. **The Controllers And The APIs They Own** lists the controllers, the API group of each one, and follows one Git revision from source-controller to kustomize-controller as an artifact. **The Flux CLI Against The Controllers** shows what each `flux` command really does to the cluster, and how to do the same with `kubectl`. **Choosing Components** explains which controllers Flux installs by default, adds the optional image automation controllers, and shows what happens to an object whose kind is not installed. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the default Flux controllers and the API group each one owns.
- Find the CustomResourceDefinitions (CRDs) Flux installed and the kinds they add.
- Explain how an artifact moves from source-controller to kustomize-controller, and read `status.artifact` on a `GitRepository`.
- Explain why the `flux` command-line tool is a client of the Kubernetes API and not part of the controllers.
- Use `flux get`, `flux events`, `flux logs`, `flux tree`, `flux reconcile`, `flux suspend` and `flux resume`, and produce YAML with `--export`.
- Add optional controllers with `flux install --components-extra` and check the result with `flux check`.
- Explain the error you get when you apply an object whose CRD is missing.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, Secrets, and the commands `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl scale`. You should know what a Git repository, a commit and a branch are. You do not need to know Flux yet.

Your playground is a single-node `kind` cluster with **Flux 2.9.6** installed by `flux install`, and the `flux` command-line tool on your PATH. It runs these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `flux-system` | The four default Flux controllers |
| Namespace `gitea` | Gitea, a Git server, with the repository `gitops/fleet`, and a `tester` pod with `curl` and `jq` |
| `GitRepository` `fleet` | Fetches `main` of `gitops/fleet` every minute |
| Flux `Kustomization` `podinfo` | Applies `./apps/podinfo` from that repository every minute |
| Namespace `podinfo` | The demo application `podinfo`: a Deployment with two pods and a Service on port `9898` |

Everything works when the playground starts. Every command in the parts runs against the playground cluster, and `kubectl` and `flux` already point at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
