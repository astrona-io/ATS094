# Welcome To The Course

This course trains you for the **Fundamentals & GitOps Toolkit Architecture** part of the Astrona **FluxCD** training path. That part is 10% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, Secrets, `kubectl apply`, `kubectl get` and `kubectl logs`. You can use Git from the terminal: clone, commit, push and pull. You do not need to know Flux or GitOps yet. Each new idea is explained the first time it appears.

## What you can do at the end

Flux runs a cluster from a Git repository, so this course does not ask you to remember words. It asks you to change Git, watch Flux change the cluster, and find out why when it does not. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **GitOps principles and the reconciliation loop**. You will learn to:

- Explain the four OpenGitOps principles and the difference between push-based and pull-based delivery.
- Make Flux apply an application from Git with a `GitRepository` and a Flux `Kustomization`.
- Watch Flux undo a manual change (drift) and delete what Git no longer holds (pruning).

Flux is not one program but a set of controllers, so the second topic is **the GitOps Toolkit architecture**. You will learn to:

- Name each Flux controller and the custom resources it owns.
- Follow one Git commit from source-controller to kustomize-controller.
- Use the `flux` command-line tool, and explain what it does through the Kubernetes API.
- Add optional controllers, such as the image automation controllers.

The third topic is **bootstrapping Flux**. You will learn to:

- Explain what `flux bootstrap` does and which files it writes to Git.
- Bootstrap Flux into a `kind` cluster from a Git repository, and verify the controllers and their custom resource definitions (CRDs).
- Explain the credentials Flux uses to read its repository, and replace one that changed.

Everything is written for **Flux v2.9.6**.

## The words this course uses

The pages use Flux's, Git's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

**GitOps** means running a system from a desired state kept in Git, which software agents pull and apply continuously. A **controller** is a program in the cluster that watches some kinds of objects and keeps changing the cluster until it matches them. One such run is a **reconciliation**. **Drift** is any difference between the cluster and Git, for example after someone runs `kubectl edit`.

Two Flux objects come back on almost every page:

| Object | What it does |
| --- | --- |
| `GitRepository` | Tells source-controller which Git repository and branch to fetch, and how often |
| Flux `Kustomization` | Tells kustomize-controller which folder of that repository to apply to the cluster, and how often |

The Flux `Kustomization` object is not the same thing as the Kustomize file `kustomization.yaml`, even though the names are alike. The pages always say which one they mean.

## The example setup in your playground

Every playground and lab runs the same small setup. A Git server called Gitea runs inside the cluster, in the namespace `gitea`. It holds one repository, `gitops/fleet`, and that repository holds the demo application `podinfo`, a small web server. Flux reads the repository and deploys `podinfo` into the namespace `podinfo`. A `tester` pod sends requests to the application and to Gitea.

You work with the repository from your own machine: you clone it, change a file, commit and push, and then watch Flux apply the change. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with what GitOps is and what Flux does with one repository, then opens Flux up to show its parts, and ends with installing Flux the way you would on a real cluster.

| Section | What it covers |
| --- | --- |
| 010 | GitOps Principles And The Reconciliation Loop |
| 020 | The GitOps Toolkit Architecture |
| 030 | Bootstrapping Flux |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
