---
estimated_duration: 30m
---

# Make Git The Only Source Of Truth

- **ID:** CAPSTONE
- **Slug:** ats-094-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Graded capstone for section 010, in the namespaces `flux-system` and `podinfo`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This capstone was written from the Flux v2.9 documentation
> and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-094-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Flux CLI, Gitea, CoreDNS rewrite and `flux install`, then the drifted starting state |
| `manifests/` | `lab-start.yaml` (Gitea, tester), `repo/` (files seeded into `gitops/fleet`, with the debug pod), `sync.yaml` |
| `solution/` | Reference solution used by `astrona test`; changes Git through the Gitea API |
| `testing/` | Waits for Gitea and the Flux controllers |
| `validation/` | Grading scripts, one per check; the drift check runs last |
