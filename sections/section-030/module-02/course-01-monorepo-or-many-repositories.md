# Monorepo Or Many Repositories

The first decision is how many Git repositories hold the desired state. Flux supports all of the choices. They differ in who can change what, how much history one clone has, and how many `GitRepository` objects you manage.

The commands below need the `GitRepository` `fleet` in the namespace `flux-system`:

<!-- astrona:playground:renew -->

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
```

## Monorepo

A **monorepo** keeps the configuration of every cluster and every application in one repository. One `GitRepository` object per cluster points at it.

- Good: one place to search, one pull request can change an application and the infrastructure it needs, and the order of changes is in one history.
- Cost: anyone who can write to the repository can change everything in it, unless the Git host limits paths. Reviews of unrelated changes share one queue.

## Repository per environment

Here staging and production each have a repository. A cluster follows one of them.

- Good: production access is a separate permission. A mistake in staging cannot touch production files.
- Cost: a change must be copied from one repository to the other. The two drift apart, and nobody sees the difference in a single `git diff`.

## Repository per team

Each team owns a repository for its applications. A platform team owns the repository for the cluster and points Flux at the team repositories.

- Good: a team changes only its own files, and the platform team controls what may be applied.
- Cost: more `GitRepository` and Flux `Kustomization` objects, and a dependency between repositories that you must keep in order.

In this model the platform repository creates the namespace, a service account and the sources for a team. The team's Flux `Kustomization` then uses `spec.serviceAccountName`, so Flux applies the team's files with only that account's permissions.

## Which one to start with

Start with a monorepo for a small organisation. Split by team when access control demands it. Keep environments as folders inside one repository, as in the earlier module, unless a rule forbids that production files sit next to staging files.

Whatever you choose, keep these facts in view:

- A `GitRepository` fetches one branch, tag, commit or semver range of one repository.
- A Flux `Kustomization` applies one folder of that source. It can only see the artifact of its own source.
- More repositories mean more places where a credential can expire.

## Try it

1. Run `flux get sources git` and read the revision of `fleet`.
2. Run `kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.ref}'` and say which part of the repository the source follows.
3. Make a second `GitRepository` named `fleet-copy` with the same address and check how many artifacts source-controller now stores with `flux get sources git`. Delete it afterwards with `flux delete source git fleet-copy --silent`.
