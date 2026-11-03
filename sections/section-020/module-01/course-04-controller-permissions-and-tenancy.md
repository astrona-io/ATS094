# Controller Permissions And Tenancy

The controllers are programs with permissions in your cluster. Which permissions they have decides what a Flux object in any namespace can change. This part shows the defaults, and the settings that limit them when several teams share a cluster.

The commands below need only the running cluster:

<!-- astrona:playground:renew -->

## What the controllers can do

`flux install` creates two cluster role bindings. Read them:

```sh
kubectl get clusterrolebinding | grep flux
kubectl get clusterrolebinding cluster-reconciler-flux-system -o yaml
```

The binding `cluster-reconciler-flux-system` gives the service accounts of kustomize-controller and helm-controller the role `cluster-admin`. They need it because they can apply any kind in any namespace. The binding `crd-controller-flux-system` gives all controllers the narrower rights to read and update the Flux kinds themselves.

The consequence is that **anyone who can create a Flux `Kustomization` can apply anything with cluster-admin rights**, unless you limit it. In a cluster of one team that is fine. In a shared cluster it is not.

## Apply as another account

A Flux `Kustomization` or a `HelmRelease` can name a service account in its own namespace. The controller then applies with the permissions of that account:

```yaml
spec:
  serviceAccountName: team-a-reconciler
```

If the account may only manage objects in its own namespace, the Flux `Kustomization` can do no more. An object that tries to create a cluster-wide resource is refused by the API server. Try it:

```sh
kubectl create namespace team-a
kubectl -n team-a create serviceaccount team-a-reconciler
kubectl -n team-a create rolebinding team-a-reconciler \
  --clusterrole=edit --serviceaccount=team-a:team-a-reconciler
kubectl auth can-i create namespaces \
  --as=system:serviceaccount:team-a:team-a-reconciler
kubectl auth can-i create deployments -n team-a \
  --as=system:serviceaccount:team-a:team-a-reconciler
```

The first answer is `no`, and the second is `yes`.

## Make it the default

A platform team sets two arguments on kustomize-controller and helm-controller so tenants cannot skip the rules:

- `--default-service-account=<name>` is used when an object does not set `serviceAccountName`. In a tenant namespace, an object that does not name an account then applies as that account.
- `--no-cross-namespace-refs=true` makes the controllers refuse a `sourceRef` that points into another namespace, and a `dependsOn` or a `valuesFrom` that does the same.

The earlier module showed how to set arguments with patches. Set these in the same way.

## Network policies

`flux install` also creates network policies in `flux-system`. Read them:

```sh
kubectl -n flux-system get networkpolicy
```

They allow traffic inside the namespace, outbound traffic from the controllers, and traffic to the metrics port. The webhook receiver of notification-controller is allowed in as well. Without a network plugin that enforces policies, they have no effect.

## Where tenants fit

In a multi-tenant layout, each team has a namespace, a service account with a role limited to that namespace, and a `GitRepository` and Flux `Kustomization` created by the platform team. The team's Flux `Kustomization` uses `serviceAccountName`, so the team can change only what its account allows.

## Try it

1. Read the cluster role binding that gives `kustomize-controller` its rights, and name the role.
2. Run the two `kubectl auth can-i` checks above. Change the `rolebinding` to `--clusterrole=view` and run the second check again.
3. Read `flux install --export | grep -B3 -A10 "kind: NetworkPolicy"` and list what the policies allow.
