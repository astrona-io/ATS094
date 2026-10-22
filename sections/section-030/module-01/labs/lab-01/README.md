---
estimated_duration: 20m
---

# Bootstrap Flux Into A Kind Cluster

- **ID:** LAB
- **Slug:** ats-094-lab-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab: Flux is not installed; the learner bootstraps it from `gitops/fleet` and deploys podinfo through Git. Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-094-lab-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-094-lab-030-01`), not
the config path.

`astrona test` runs `solution/apply.sh`, which starts its own background
`kubectl port-forward` to Gitea on port 3000. Port 3000 must be free, and
`gitea.localtest.me` must resolve to `127.0.0.1` on the machine (add
`127.0.0.1 gitea.localtest.me` to `/etc/hosts` if a router blocks it).

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation run once at startup |
| `manifests/` | Gitea and tester (`lab-start.yaml`) and the files seeded into `gitops/fleet` (`repo/`) |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs first |
| `validation/` | Grading scripts, one per check |
