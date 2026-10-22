---
estimated_duration: 15m
---

# Add The Image Automation Controllers

- **ID:** LAB
- **Slug:** ats-094-lab-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `flux-system`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Flux v2.9 documentation and has not
passed `astrona validate` or `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-094-lab-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-lab-020-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation run once at startup |
| `manifests/` | Gitea, the seeded repository files, and the `ImageRepository` used by the reference solution |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs before the reference solution |
| `validation/` | Grading scripts, one per check |
