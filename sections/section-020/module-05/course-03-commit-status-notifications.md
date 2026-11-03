# Commit Status Notifications

Chat messages tell people about a deployment. A commit status tells the Git host. With a commit status, the pull request or the commit shows whether Flux applied it successfully. This closes the loop from Git to the cluster and back to Git.

The commands below need the `GitRepository` `fleet` and the Flux `Kustomization` `podinfo` from the earlier parts:

<!-- astrona:playground:renew -->

## Which providers support it

The providers `github`, `gitlab`, `gitea`, `bitbucket`, `bitbucketserver` and `azuredevops` set a status on a commit. Use the type that matches your Git host. The `address` is the URL of the repository, not a webhook, and the Secret holds a token that is allowed to write statuses.

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: gitea-status
  namespace: flux-system
spec:
  type: gitea
  address: http://gitea.localtest.me:3000/gitops/fleet
  secretRef:
    name: gitea-token
```

The Secret has the key `token`. Create a token for the user with the permission to write commit statuses, and keep it read-limited to this one repository where the host allows it.

## The Alert

The event source is the Flux `Kustomization` that applies the repository. The event carries the revision it applied, and the provider sets the status on that commit:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: commit-status
  namespace: flux-system
spec:
  providerRef:
    name: gitea-status
  eventSources:
    - kind: Kustomization
      name: podinfo
```

The status shows success after a successful apply and failure after an error. Whether a pull request can be blocked by it depends on the rules of the Git host.

## What it needs

- The events must carry a revision. Events of the Flux `Kustomization` do.
- With `wait: true` or health checks on the Flux `Kustomization`, a success status is sent only when the workloads are healthy. Without them, the status means only that the apply finished.
- The token must be valid. A wrong token does not break the Flux `Kustomization`, but notification-controller logs the error, and the status never appears. Read `flux logs --kind=Alert` when the status is missing.
- Because the status is written for a commit in the repository that the Flux `Kustomization` applies, use the same repository URL as the `GitRepository`.

## Other Git-related providers

The `githubdispatch` provider starts a GitHub Actions workflow when an event arrives. It lets a pipeline continue after Flux finished a deployment, for example with a smoke test. Other types, such as `alertmanager` and `pagerduty`, route failures into incident tools.

## Try it

1. Write the `Provider` and `Alert` for your Git host in a file, and use `kubectl apply --dry-run=server` to check that the API accepts them.
2. List the keys a `Secret` for the type needs. Which one is a token and which one an address?
3. Explain in one sentence why `wait: true` matters for a commit status.
