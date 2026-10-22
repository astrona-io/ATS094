---
estimated_duration: 15m
---

# Make Flux Apply The Application From Git

- **ID:** LAB
- **Slug:** ats-094-lab-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespaces `flux-system` and `podinfo`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Flux v2.9 documentation and
> has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-094-lab-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-lab-010-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough with a submit loop |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Flux CLI, Gitea, CoreDNS rewrite and `flux install`, then the broken Flux objects |
| `manifests/` | `lab-start.yaml` (Gitea, tester), `repo/` (files seeded into `gitops/fleet`), `broken-sync.yaml` |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for Gitea and the Flux controllers |
| `validation/` | Grading scripts, one per check |
