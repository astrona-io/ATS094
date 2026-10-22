# Find Your Way Around The GitOps Toolkit — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-094-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Gitea, the seeded `gitops/fleet` repository,
the four default Flux controllers, and a GitRepository `fleet` plus a Flux
Kustomization `podinfo` that are already reconciling. Nothing to submit.

Not yet run: this playground was written from the Flux v2.9 documentation and
has not been started on a cluster yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-094-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup |
| `manifests/lab-start.yaml` | Gitea and the tester pod |
| `manifests/repo/` | Files seeded into `gitops/fleet` |
| `manifests/flux-sync.yaml` | The GitRepository `fleet` and the Flux Kustomization `podinfo` |
| `docs/overview.md` | What the environment contains and ideas to try |
