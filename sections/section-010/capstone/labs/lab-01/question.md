# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** GitOps principles and the reconciliation loop

## Scenario

The team that runs `podinfo` stopped trusting Flux. During an incident, someone suspended the Flux `Kustomization` `podinfo` and scaled the Deployment to 5 replicas by hand. Earlier, someone committed a debugging pod to `apps/podinfo` "for a day", and pruning was switched off "to be safe". Now Git says one thing and the cluster runs another, and nobody knows which one is right.

The team has decided: **podinfo runs 3 replicas, and the debug pod must go.** From now on, Git alone decides what runs.

## Your task

1. Find every way in which the cluster and Git disagree, and every setting that stops Flux from fixing it.
2. Make the decision in Git: `podinfo` runs 3 replicas, and the debug pod is no longer part of `apps/podinfo`.
3. Make Flux apply Git again and remove from the cluster what Git no longer holds.

## Constraints

- **Change the application through Git only.** Clone `gitops/fleet`, commit and push. Do not set the replicas with `kubectl scale` and do not delete the debug pod with `kubectl delete`: Flux must remove it.
- Keep the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` with their names, repository and path. Do not create new Flux objects.
- The Flux `Kustomization` `podinfo` must end up not suspended, with `prune: true`.

## Done when

- `flux get kustomizations` shows `podinfo` `Ready`, not suspended, on the same revision as `flux get sources git`.
- In Git, on `main`, `apps/podinfo/deployment.yaml` says `replicas: 3`, and neither the file `debug-pod.yaml` nor a line for it in `kustomization.yaml` is left.
- The Deployment `podinfo` runs 3 ready replicas, and the pod `debug` no longer exists.
- If someone scales `podinfo` by hand, the next reconciliation puts it back to 3.
