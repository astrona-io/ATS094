---
estimated_duration: 30m
---

# Find The Controller That Stopped Working

- **ID:** CAPSTONE
- **Slug:** ats-094-capstone-020
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab (section capstone)

Graded capstone for the namespaces `flux-system` and `podinfo`. Two independent
faults: `kustomize-controller` is scaled to zero, and the `GitRepository`
`fleet` points at a repository that does not exist. Read `question.md` for the
task; `solution.md` is the walkthrough.

Not yet run: this capstone was written from the Flux v2.9 documentation and
has not passed `astrona validate` or `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-094-capstone-020
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-capstone-020`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation and the broken starting state |
| `manifests/` | Gitea, the seeded repository files, and the broken Git sync |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs before the reference solution |
| `validation/` | Grading scripts, one per check |
