# Service Accounts And Tenant Isolation

By default kustomize-controller applies objects with its own identity, which has cluster-admin rights. That is right for a platform team that owns the cluster. It is wrong when several teams share one cluster: a team that can create a Flux `Kustomization` could apply anything, including objects in another team's namespace.

The field `spec.serviceAccountName` fixes this. The controller then impersonates the named service account, so the apply is allowed only where that account has permissions.

The commands below need the `GitRepository` `fleet` in the namespace `flux-system` and the Flux `Kustomization` `templated` from the earlier part:

<!-- astrona:playground:renew -->

## Impersonation

The service account must be in the same namespace as the Flux `Kustomization`. Everything the controller does for that object, including applying, pruning and checking health, is done as that account. The controller needs the right to impersonate service accounts, and the standard Flux installation grants it.

Create a service account with limited rights, and make the Flux `Kustomization` use it:

```sh
kubectl -n flux-system create serviceaccount templated-applier
kubectl -n templated create role applier \
  --verb=get,list,watch,create,update,patch,delete \
  --resource=deployments.apps
kubectl -n templated create rolebinding applier \
  --role=applier --serviceaccount=flux-system:templated-applier
kubectl -n flux-system patch kustomization templated --type=merge \
  -p '{"spec":{"serviceAccountName":"templated-applier"}}'
flux reconcile kustomization templated
kubectl -n flux-system get kustomization templated \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The role allows only Deployments in the namespace `templated`. The folder also contains a Namespace object, which is cluster-scoped, so the account cannot apply it, and the message reports a permission error that names the account and the object. That is the behaviour you want: the account cannot do more than the role allows. Read the message to see exactly which verb on which resource is missing, add it to the role if the team should have it, and reconcile again.

## Least privilege in practice

Give each team a namespace, a service account and a Role that covers only what the team deploys. Cluster-scoped objects such as Namespaces, CustomResourceDefinitions and ClusterRoles stay with the platform team. If a team applies a ClusterRole, a restricted account fails the apply, and the team cannot give itself more rights.

Prune and health checks use the same account. If it cannot delete an object, prune fails. If it cannot read the status of a workload, `wait` fails. A permission problem often looks like a stuck object, so read the message before you look at the workload.

## Making it mandatory

An attribute on the Flux `Kustomization` is a choice, and a tenant can leave it out. Platform teams enforce the rule with options of the controller:

| Flag of kustomize-controller | Effect |
| --- | --- |
| `--default-service-account=NAME` | A Flux `Kustomization` without `serviceAccountName` uses this account in its own namespace |
| `--no-cross-namespace-refs=true` | A Flux `Kustomization` can refer to a source and to dependencies only in its own namespace |

The flags are set on the Deployment of the controller, usually with a patch in the `flux-system` Kustomization that bootstraps Flux. With both set, a tenant can only deploy with the rights of an account in its namespace, from a source in its namespace.

## Other clusters

The field `spec.kubeConfig` points to a Secret that holds a kubeconfig, so one Flux installation can apply to another cluster. Combine it with the same ideas: the credentials in the kubeconfig decide what the Flux `Kustomization` is allowed to do there. A kubeconfig for a cluster-admin user gives a Flux `Kustomization` cluster-admin rights on that cluster.

## Reading the three kinds of error

You now know the three steps and where each fails. Use the `Ready` message to find the step:

| What the message talks about | Step | Where to fix |
| --- | --- | --- |
| Files, resources, patches or YAML | Build | Git |
| A ConfigMap or Secret from `substituteFrom` | Substitute | The Flux `Kustomization` or the variable source |
| `forbidden`, a namespace or an invalid field | Apply | Rights of the account, the namespace, or the manifest |
| A workload that is not ready | Wait | The workload |

## Try it

1. Create the service account, role and binding, set `serviceAccountName`, and read the message. Which object and verb does it name?
2. Remove `serviceAccountName` again and reconcile. Does the Flux `Kustomization` become ready?
3. Write down which of the four steps in the table each of your own earlier errors belonged to.
