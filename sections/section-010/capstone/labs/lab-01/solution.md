# Solution: Make Git The Only Source Of Truth

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the Flux `Kustomization` `podinfo` is active, prunes, and applied the latest revision; Git asks for 3 replicas and holds no debug pod; the cluster matches Git; and a manual scale is put back by Flux.

## Step 1: Find every difference

Start with the Flux objects:

```sh
flux get sources git
flux get kustomizations
kubectl -n flux-system get kustomization podinfo -o jsonpath='{.spec.prune}{" "}{.spec.suspend}{"\n"}'
```

The source `fleet` is `Ready`. The Flux `Kustomization` `podinfo` shows `SUSPENDED` as `True`, and the last command prints `false true`: pruning is off and the object is suspended. Now compare the cluster with Git:

```sh
kubectl -n podinfo get deployment podinfo
kubectl -n podinfo get pods
```

The Deployment runs 5 replicas, and a pod named `debug` runs next to the `podinfo` pods. Three things are wrong: the replica count in the cluster does not match any decision in Git, the debug pod is part of the desired state, and Flux is stopped in two ways.

## Step 2: Turn pruning on first, while the object is still suspended

Order matters here. kustomize-controller deletes an object only if the object is in its inventory and `prune` is `true` at the moment it applies a revision without that object. If Flux applied the new revision with `prune: false`, the debug pod would drop out of the inventory and never be deleted. So switch pruning on while nothing is applied:

```sh
kubectl -n flux-system patch kustomization podinfo --type=merge -p '{"spec":{"prune":true}}'
```

The object stays suspended, so nothing happens yet.

## Step 3: Make the decision in Git

Start the port-forward to Gitea in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In your first terminal, clone the repository (lab-only credentials in the URL):

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
```

Make three changes with an editor: in `apps/podinfo/deployment.yaml`, change `replicas: 2` to `replicas: 3`; in `apps/podinfo/kustomization.yaml`, remove the line `- debug-pod.yaml`; and delete the file itself. Then commit and push:

```sh
git rm apps/podinfo/debug-pod.yaml
git commit -am "Run podinfo with 3 replicas and remove the debug pod"
git push
```

Note that Git said 2 replicas, not 5. The 5 was never a decision in Git; it was drift, and it is now replaced by the team's decision.

## Step 4: Resume and apply

Resume the Flux `Kustomization`. `flux resume` sets `suspend` to `false` and asks for a reconciliation. Then make sure the new commit is fetched and applied:

```sh
flux resume kustomization podinfo
flux reconcile kustomization podinfo --with-source
flux events --for Kustomization/podinfo
```

The events show kustomize-controller configuring the Deployment and deleting the pod `debug`. It deleted the pod because the pod was in the inventory, `prune` was `true`, and the new revision no longer had it. The pod then shows `Terminating` for up to 30 seconds: its shell ignores the stop signal, so the kubelet waits for the full grace period before it removes the pod.

## Step 5: Prove the fix

Check the Flux objects and the cluster:

```sh
flux get sources git
flux get kustomizations
kubectl -n podinfo get deployment podinfo
kubectl -n podinfo get pod debug
```

Both Flux objects show the same revision, `podinfo` is not suspended, the Deployment shows `3/3`, and the last command reports that the pod `debug` is not found. Now test the drift correction yourself, the same way the grader does:

```sh
kubectl -n podinfo scale deployment podinfo --replicas=1
flux reconcile kustomization podinfo
kubectl -n podinfo get deployment podinfo
```

The Deployment is back at 3 replicas.

## Step 6: Submit

Send the capstone for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `kubectl scale --replicas=3` | The cluster looks right, but Git still says 2, so Flux sets 2 at its next run. The grader reads Git |
| `kubectl delete pod debug` | The pod is gone, but Git still holds it, so Flux creates it again |
| Resume before turning on `prune` | Flux applies the new revision without pruning, the debug pod drops out of the inventory, and Flux never deletes it |
| Leave `podinfo` suspended and fix the cluster by hand | Nothing reconciles, so the next manual change stays forever |

## Common mistakes

- Removing `debug-pod.yaml` but leaving its line in `kustomization.yaml`. Kustomize then cannot build the folder, and the Flux `Kustomization` reports a build error.
- Pushing without the port-forward running. `git push` fails to connect.
- Treating 5 as the right value because it is what runs. The running value is only drift until Git says it.

## Practice on your own

- Add the annotation `kustomize.toolkit.fluxcd.io/prune: disabled` to the debug pod in Git, then remove the file, and explain why the pod stays.
- Suspend `podinfo`, push a commit, and compare the revisions in `flux get sources git` and `flux get kustomizations`.
