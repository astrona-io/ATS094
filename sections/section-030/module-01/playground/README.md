# Bootstrap Flux From A Git Repository — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-094-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Gitea, the repository `gitops/fleet` seeded
with podinfo, and the Flux CLI 2.9.6. Flux itself is **not** installed: the
module bootstraps it.

## Run it

```sh
astrona run -c .
astrona destroy ats-094-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-playground-030-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Flux CLI, Gitea, CoreDNS rewrite, user, repository and seed |
| `manifests/lab-start.yaml` | Gitea and the tester pod |
| `manifests/repo/` | Files committed to `gitops/fleet` at start |
| `docs/overview.md` | What the environment contains and ideas to try |
