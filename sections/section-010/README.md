# Section 010: GitOps Principles And The Reconciliation Loop

Most teams start by deploying with a pipeline that runs `kubectl apply` against the cluster. That works until someone changes the cluster by hand, or the pipeline fails halfway, and nobody can say any more what should be running. GitOps answers that question with one rule: the desired state lives in Git, and software inside the cluster keeps the cluster equal to it.

This section shows that rule at work with Flux. You first learn the four OpenGitOps principles and why a pull-based agent inside the cluster is different from a push-based pipeline outside it. Then you create the two Flux objects that make the loop run: a `GitRepository`, which fetches the repository, and a Flux `Kustomization`, which applies one folder of it. Last, you see what the loop does to manual changes and to objects that disappear from Git.

**Topic covered:** GitOps principles

## What you will learn

- The four OpenGitOps principles: declarative, versioned and immutable, pulled automatically, continuously reconciled.
- The difference between push-based delivery from a pipeline and pull-based delivery by an agent in the cluster.
- Where Flux v2 fits: a graduated project of the Cloud Native Computing Foundation (CNCF), built as a set of controllers called the GitOps Toolkit.
- Creating a `GitRepository` with a credentials Secret, and a Flux `Kustomization` that applies one path of it.
- Reading `flux get` and `flux events` to see whether a source and a sync are `Ready`, and which revision they hold.
- Changing an application through a Git commit and forcing a reconciliation with `flux reconcile`.
- Drift correction, pruning, suspending a Flux `Kustomization`, and the annotations that exclude one object.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Reconcile A Cluster From Git With Flux

The module starts at its landing page, which also launches the playground. The playground holds an in-cluster Git server (Gitea) with the repository `gitops/fleet`, which contains the `podinfo` application, and the Flux controllers, installed but not yet pointed at any repository.

1. GitOps Principles And Pull-Based Delivery
2. Your First GitRepository And Kustomization, followed by the lab **Make Flux Apply The Application From Git**
3. Drift Correction And Pruning
4. Summary

## Section capstone: Make Git The Only Source Of Truth

The capstone is one graded scenario that combines the whole module. The team that runs `podinfo` stopped trusting Flux: someone suspended the sync, scaled the Deployment by hand, and left a debugging pod in Git. Git and the cluster no longer agree, and pruning is switched off, so Flux would not clean up even if it ran. Bring the two back together so that Git alone decides what runs. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-094-capstone-010
```
