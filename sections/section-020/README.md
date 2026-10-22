# Section 020: The GitOps Toolkit Architecture

Flux is not one program. It is a set of controllers, and each one owns a few kinds of custom resources. When something does not reconcile, the first question is always which controller should have done the work, and whether it is running. A reader who sees Flux as one block cannot answer that question.

This section takes Flux apart. You see which controller owns which API, how a source revision travels from source-controller to kustomize-controller as an artifact, and why the `flux` command-line tool is only a client of those controllers. You also learn which controllers Flux installs by default, and how to add the optional ones.

**Topic covered:** The GitOps Toolkit

## What you will learn

- The four default controllers, the optional image automation controllers, and the API group each one owns.
- How source-controller turns a Git revision into an artifact, and how kustomize-controller downloads and applies it.
- Reading the CustomResourceDefinitions (CRDs) and the `status.artifact` of a `GitRepository`.
- What the `flux` command-line tool does: it reads and writes custom resources through the Kubernetes API, and nothing else.
- Using `flux get`, `flux events`, `flux logs`, `flux tree`, `flux reconcile`, `flux suspend`, `flux resume` and `--export`.
- Adding optional components with `flux install --components-extra`, and checking the result with `flux check`.
- What happens when you apply an object whose CRD is not installed.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Find Your Way Around The GitOps Toolkit

The module starts at its landing page, which also launches the playground. The playground runs Flux with its four default controllers, a Git server with the repository `gitops/fleet`, and a `GitRepository` and a Flux `Kustomization` that already apply the `podinfo` application.

1. The Controllers And The APIs They Own
2. The Flux CLI Against The Controllers
3. Choosing Components, followed by the lab **Add The Image Automation Controllers**
4. Summary

## Section capstone: Find The Controller That Stopped Working

The capstone is one graded scenario that uses the whole module. The application `podinfo` should be running from Git, but nothing reconciles, and there are two independent faults in two different controllers' areas. You must find each one with the Flux tools, fix it without deleting the Flux objects, and prove that Flux applies the application again. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-094-capstone-020
```
