# Reconcile A Cluster From Git With Flux — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-094-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

> **Not yet run.** This playground was written from the Flux v2.9
> documentation and has not been started on a cluster yet.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-094-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-playground-010-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Flux CLI, Gitea, CoreDNS rewrite, repository seed, `flux install` |
| `manifests/lab-start.yaml` | Gitea and the tester pod |
| `manifests/repo/` | Files committed to `gitops/fleet` at startup (`apps/podinfo`, `clusters/kind`) |
| `docs/overview.md` | What the environment contains and ideas to try |
