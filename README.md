# ATS094 — Fundamentals & GitOps Toolkit Architecture (FluxCD)

Course material for the **Fundamentals & GitOps Toolkit Architecture** domain
of the Astrona FluxCD training path ([ATP019](https://github.com/astrona-io/ATP019)),
which is **10% of the path**. Written for **Flux v2.9.6**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Flux v2.9 documentation. None has been started on a cluster, and
> no lab has passed `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | GitOps Principles And The Reconciliation Loop | 1 | 1 + capstone | GitOps principles |
| [020](sections/section-020) | The GitOps Toolkit Architecture | 1 | 1 + capstone | GitOps Toolkit |
| [030](sections/section-030) | Bootstrapping Flux | 1 | 1 + capstone | Bootstrap |

The order goes from use to installation. Section 010 starts with what Flux
does for one repository. Section 020 opens Flux up into its controllers and
shows what the `flux` command really does. Section 030 ends with
`flux bootstrap`, the way Flux is installed on a real cluster, which only
makes sense once you know what it installs.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Reconcile A Cluster From Git With Flux](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Find Your Way Around The GitOps Toolkit](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Bootstrap Flux From A Git Repository](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Make Git The Only Source Of Truth | a suspended Kustomization, pruning off, a manual scale, an object that should not exist |
| [020](sections/section-020/capstone/labs/lab-01) | Find The Controller That Stopped Working | kustomize-controller scaled to zero, a GitRepository with a wrong URL |
| [030](sections/section-030/capstone/labs/lab-01) | Recover A Cluster Whose Bootstrap Broke | a rotated Git password, a changed sync path, a broken application path in Git |

---

## The lab environment

Every playground and lab is a **kind** cluster with an in-cluster Git server
(Gitea, `gitea/gitea:28.2.0-rootless`) holding the repository `gitops/fleet`,
and the Flux CLI 2.9.6 installed on the machine. Sections 010 and 020 start
with the Flux controllers installed; section 030 starts without them, because
installing them is the task.

The repository address is `http://gitea.localtest.me:3000/gitops/fleet.git`
everywhere: on the reader's machine through
`kubectl -n gitea port-forward svc/gitea-http 3000:3000`, and inside the
cluster through a CoreDNS rewrite added by the bootstrap. Credentials are the
lab-only `gitops` / `gitops-password`.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final cluster and Git state** with independent checks,
and several of them deliberately reject the plausible-but-wrong fix (applying
the application with `kubectl`, suspending the failing object, deleting and
recreating Flux objects, reinstalling Flux by hand).
