# Desired State, Actual State And The OpenGitOps Principles

GitOps is a way to run a system, not a product. It rests on a small number of ideas. This part defines them in plain words and shows where each one appears in Flux.

The commands below need a `GitRepository` named `fleet` and a Flux `Kustomization` named `namespaces` in the namespace `flux-system`:

<!-- astrona:playground:renew -->

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
flux create kustomization namespaces \
  --source=GitRepository/fleet --path=./infrastructure/namespaces \
  --prune=true --wait=true --interval=5m
```

## Desired state and actual state

The **desired state** is what you want the system to look like. In GitOps it is written down as files in a Git repository: Kubernetes manifests, Kustomize files, Helm release definitions. The **actual state** is what the cluster contains right now, read from the Kubernetes API.

The two can differ. A new commit changes the desired state, so for a short time the actual state is behind. Someone running `kubectl edit` changes the actual state without changing Git. A difference between the two is called **drift**.

**Reconciliation** is the work of finding the difference and removing it. It always moves the actual state toward the desired state, never the other way. Flux does this on a loop: read the desired state, read the actual state, apply the difference, report the result in the status of the object.

## The four OpenGitOps principles

The OpenGitOps working group states GitOps as four principles. Each one has a concrete form in Flux.

1. **Declarative.** A system managed by GitOps must have its desired state expressed declaratively. The files say what should exist, not the steps to create it. A Deployment manifest is declarative. A shell script that runs `kubectl create` is not.
2. **Versioned and immutable.** The desired state is stored in a way that enforces immutability and keeps a complete version history. In Flux this is a Git commit. A commit hash names exactly one state of the files, and it never changes.
3. **Pulled automatically.** Software agents automatically pull the desired state from the source. In Flux the agents run inside the cluster and fetch from Git. Nothing outside the cluster needs credentials to change it.
4. **Continuously reconciled.** Software agents continuously observe the actual state and try to apply the desired state. In Flux this is the interval on each object and the retry after a failure.

## Pull-based and push-based delivery

In **push-based** delivery, a pipeline outside the cluster runs a command such as `kubectl apply` or `helm upgrade` after a build. The pipeline needs credentials for the cluster. It changes the cluster only when it runs, so a change made by hand between two runs stays in place and nobody is told.

In **pull-based** delivery, an agent inside the cluster reads from Git. The cluster credentials stay in the cluster. The agent keeps running, so it also notices and removes drift. Flux is pull-based. Your continuous integration pipeline still has a job: it builds and tests an image and, at most, writes the new image tag into Git. Delivery to the cluster is Flux's job.

## Where these ideas appear in Flux

| Idea | In Flux |
| --- | --- |
| Desired state | The files in the repository, fetched by a `GitRepository` |
| Actual state | The objects in the cluster |
| Version history | Git commits; the applied commit is in `status.lastAppliedRevision` |
| Pulled | source-controller and kustomize-controller run in `flux-system` and fetch |
| Continuously reconciled | `spec.interval` on each object |
| Drift correction | Re-applying the desired state on every reconcile |
| Pruning | `spec.prune: true` deletes objects that are no longer in Git |

## Try it

1. Run `flux get sources git` and `flux get kustomizations`. Which commit does each one show?
2. Run `kubectl get namespaces`. Which two namespaces now exist, and which file in the repository created them?
3. Run `kubectl delete namespace staging`, then `flux reconcile kustomization namespaces`. What does `kubectl get namespaces` show now? Which principle is that?
4. Run `kubectl label namespace production owner=hand`. Reconcile again and read the labels with `kubectl get namespace production --show-labels`. Does the label survive? Think about why that depends on which fields Git declares.
