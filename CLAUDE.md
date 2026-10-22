# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS094 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Fundamentals & GitOps Toolkit Architecture**
  domain of the **FluxCD** training path (`ATP019`). It is 10% of the path.
  There is no official Flux certification exam; the path's domains and weights
  are Astrona's own, set in `ATP019/path.yaml`. (The Certified GitOps
  Associate exam covers Flux only as one tool among several.)
- **What the domain really tests:** making Flux run a cluster from Git, not
  remembering words. The student must *do* things (push a change and watch
  Flux apply it, find which controller owns a failing object, read
  `flux get` and `flux events`, bootstrap Flux into a cluster, verify the
  CRDs). Every explanation should lead to a command they can run, and every
  fix should be proved with an object that becomes `Ready` and a workload
  that matches what Git says.
- **The three topics:** GitOps principles and the reconciliation loop, the
  GitOps Toolkit (GOTK) architecture and the Flux command-line tool, and
  bootstrapping Flux. The README table maps each section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | GitOps Principles And The Reconciliation Loop | GitOps principles |
  | 020 | The GitOps Toolkit Architecture | GitOps Toolkit |
  | 030 | Bootstrapping Flux | Bootstrap |

- **The version:** everything is written for **Flux v2.9.6** (CLI and
  controllers) on a single-node `kind` cluster. Flux 2.9 supports Kubernetes
  1.34.1 or later, so the `kind` node must be at least that version. Do not
  teach fields, flags or output from other versions without saying so.
- **The main sources:** the Flux documentation, <https://fluxcd.io/flux/>.
  Check every page against it.

### Status: built, not yet run

The first version of this repository was written from the Flux v2.9
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The biggest open risk is **Git credentials over plain HTTP**. The Flux
documentation describes basic authentication for HTTPS only, and the
repository `gitops/fleet` is private, so every `GitRepository` sends the
`gitops` credentials to `http://gitea.localtest.me:3000`. If source-controller
or `flux create secret git` refuses that, every environment fails at the first
fetch. Check this first; the fallback is Gitea on HTTPS with a self-signed
certificate (`--ca-file` for bootstrap, `caFile` in the Secret).

### Terms, not metaphors

Explanations use Flux's, Git's and Kubernetes' own words. Define each one in
plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| GitOps | Running a system from a desired state kept in Git, which software agents pull and apply continuously |
| OpenGitOps principles | The four GitOps principles: declarative, versioned and immutable, pulled automatically, continuously reconciled |
| Push-based / pull-based delivery | A pipeline outside the cluster runs `kubectl apply` / an agent inside the cluster fetches the desired state and applies it |
| Reconciliation | One run of a controller that compares the desired state with the live state and changes the live state to match |
| Drift | A difference between the live state and the desired state, for example after a manual `kubectl edit` |
| GitOps Toolkit (GOTK) | The set of Flux controllers and APIs; each controller owns its own custom resources |
| Controller | A program in the cluster that watches custom resources of some kinds and reconciles them |
| Custom resource definition (CRD) | A schema that adds a new resource kind, such as `GitRepository`, to the Kubernetes API |
| source-controller | Fetches sources (`GitRepository`, `OCIRepository`, `HelmRepository`, `Bucket`) and stores each revision as an artifact |
| Artifact | A `tar.gz` file of one source revision that source-controller serves over HTTP inside the cluster |
| kustomize-controller | Builds a `Kustomization`'s path from an artifact and applies the result with server-side apply |
| helm-controller / notification-controller | Installs and upgrades `HelmRelease`s / sends and receives events (`Provider`, `Alert`, `Receiver`) |
| image-reflector-controller / image-automation-controller | Optional; scan image registries / write new image tags back to Git |
| `Kustomization` (Flux) | The Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`; not the same as the Kustomize file `kustomization.yaml` |
| Bootstrap | `flux bootstrap`: installs the controllers, commits their manifests to Git, and makes Flux reconcile itself from that repository |
| `flux-system` | The namespace, `GitRepository`, `Kustomization` and `Secret` that bootstrap creates |
| Deploy key | An SSH key that gives access to one repository only, read-only or read-write |
| Prune | Deleting objects from the cluster that were applied before and are no longer in Git |

The `Kustomization` name clash confuses every learner. On first use in a
file, always say which one you mean: "the Flux `Kustomization` object" or
"the Kustomize file `kustomization.yaml`".

### The example workloads

| Name | Image | What it is |
| --- | --- | --- |
| `gitea` (Deployment and Service `gitea-http`, namespace `gitea`) | `gitea/gitea:28.2.0-rootless` | The in-cluster Git server. HTTP on port `3000`. SQLite storage on an `emptyDir`, so a restart loses every repository |
| Gitea user `gitops` | | Password `gitops-password`, administrator. Lab-only credentials; say so when a page uses them |
| Repository `gitops/fleet` | | The cluster's Git repository. Every module seeds it with its own starting files |
| `podinfo` (Deployment and Service) | `ghcr.io/stefanprodan/podinfo:6.15.0` | The demo application Flux deploys, port `9898`, in the namespace `podinfo` |
| `tester` (namespace `gitea`) | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Graders call the Gitea API and podinfo from here; Git work happens on the reader's machine |

The repository layout follows the Flux convention:

```text
fleet/
├── apps/podinfo/          # namespace.yaml, deployment.yaml, service.yaml, kustomization.yaml
└── clusters/kind/         # what Flux reconciles for this cluster
    └── flux-system/       # written by flux bootstrap (section 030 only)
```

### Environment facts the text must respect

- **One Git address that works everywhere: `http://gitea.localtest.me:3000`.**
  The public DNS name `gitea.localtest.me` resolves to `127.0.0.1`. On the
  reader's machine, `kubectl -n gitea port-forward svc/gitea-http 3000:3000`
  makes Gitea answer there. Inside the cluster, the bootstrap adds a CoreDNS
  `rewrite stop` block so the same name resolves to
  `gitea-http.gitea.svc.cluster.local`, and rewrites the answer name back to
  `gitea.localtest.me` (Go programs, Flux included, ignore an answer whose name
  differs from the question). Copy the block from
  `sections/section-010/module-01/playground/bootstrap/prepare.sh`; never the
  one-line `rewrite name` form.
  So the URL in a `GitRepository`, in `flux bootstrap git` and in
  `git clone` is always `http://gitea.localtest.me:3000/gitops/fleet.git`.
  Explain this in one plain sentence where a page needs it; it is lab
  plumbing, not Flux content. Some home routers block DNS answers that point
  at `127.0.0.1` (DNS rebinding protection); then the reader adds
  `127.0.0.1 gitea.localtest.me` to `/etc/hosts`. Every page that clones says
  so in one sentence.
- **The port-forward must be running** for every `git` and `flux bootstrap`
  command on the reader's machine. Pages start it in a second terminal and say
  so. Controllers inside the cluster do not need it.
- **HTTP, not HTTPS.** Gitea runs without TLS, so `flux bootstrap git` needs
  `--allow-insecure-http` and `--token-auth` with `--username gitops
  --password gitops-password`. Say on every such page that a real Git server
  uses HTTPS or SSH and that this is lab-only.
- **Flux CLI on the reader's machine.** Playgrounds and labs install `flux`
  2.9.6 from the GitHub release tarball into `/usr/local/bin` or
  `~/.local/bin`, the same way for every environment.
- **Flux facts (from the documentation, not yet seen on a run):**
  - Default components: `source-controller`, `kustomize-controller`,
    `helm-controller`, `notification-controller`. Extra components through
    `--components-extra`: `image-reflector-controller`,
    `image-automation-controller`, `source-watcher`.
  - API versions: `source.toolkit.fluxcd.io/v1` (`GitRepository`,
    `OCIRepository`, `HelmRepository`, `HelmChart`, `Bucket`,
    `ExternalArtifact`, `ArtifactGenerator`), `kustomize.toolkit.fluxcd.io/v1`
    (`Kustomization`), `helm.toolkit.fluxcd.io/v2` (`HelmRelease`),
    `notification.toolkit.fluxcd.io` (`Provider`, `Alert`, `Receiver`),
    `image.toolkit.fluxcd.io/v1` (`ImageRepository`, `ImagePolicy`,
    `ImageUpdateAutomation`).
  - `flux bootstrap` is idempotent: running it again upgrades Flux and
    changes nothing else. `--interval` defaults to `1m0s`, `--branch` to
    `main`, `--network-policy` to `true`, `--secret-name` to `flux-system`.
  - With SSH, bootstrap generates an ECDSA P-384 key by default and stores the
    private key in the Secret `flux-system` in the namespace `flux-system`.
  - Bootstrap writes `gotk-components.yaml`, `gotk-sync.yaml` and
    `kustomization.yaml` under `<path>/flux-system/`.
  - `flux install` installs the controllers without Git; it is for
    development and testing.
- **Many environments start broken on purpose.** A lab seeds a fault in Git
  or in the cluster (a wrong branch, a wrong path, a scaled-down controller, a
  stale credential). The fault is the material. Never "fix" it in the
  bootstrap.
- **The proof is the cluster matching Git.** A fix is proven with
  `flux get` showing `Ready True` and the expected revision, plus the
  workload itself (`kubectl get`, or a request to podinfo from `tester`).
  Where a page tests drift correction, it changes the live object and runs
  `flux reconcile kustomization <name> --with-source` instead of waiting.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-install-git-and-flux.sh`, `02-seed-state.sh` | Gitea, the CoreDNS rewrite, the Flux CLI (and Flux, where the lab starts with it), and the starting state |
| `manifests/` | `lab-start.yaml` (Gitea and tester) and any extra objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-flux.sh` | Waits until Gitea and the Flux controllers answer before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS094`, domain
`Fundamentals & GitOps Toolkit Architecture`, weight `10`) and one entry per
section under `modules:` (`module-010`, `module-020`, `module-030`). Each
section's `content` lists, in order: the section `README.md`, then for each
module its landing page, its parts, and right after the part a lab tests, a
`Question` reading (`labs/lab-01/question.md`) followed by the `type: lab`
entry; the module's closing page comes last. The section capstone closes the
section. Playgrounds are not listed.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`.
- `topic`: exactly one of `gitops-principles`, `reconciliation`,
  `toolkit-architecture`, `cli`, `bootstrap`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `fluxcd.io` (or `opengitops.dev`), each with a
  `name` and a `url` that loads. This is the **only** place outside links are
  allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Principles: `opengitops`, `pull-based`, `desired-state`, `drift-detection`,
  `reconciliation`, `prune`
- Sources and sync: `gitrepository`, `kustomization`, `kustomize-file`,
  `branch`, `path`, `interval`, `artifact`
- Toolkit: `source-controller`, `kustomize-controller`, `helm-controller`,
  `notification-controller`, `image-controllers`, `crds`, `components-extra`
- CLI: `flux-cli`, `flux-check`, `flux-get`, `flux-events`, `flux-logs`,
  `flux-reconcile`, `flux-export`
- Bootstrap: `flux-bootstrap`, `flux-system`, `git-credentials`,
  `deploy-key`, `gitea`, `self-management`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-010/module-01/playground
astrona destroy ats-094-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-094-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-094-playground-<section>-<module>`, a module lab
is `ats-094-lab-<section>-<module>` and a capstone is
`ats-094-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: a `Ready`
condition with the expected revision, the workload matching Git, and drift
put back by Flux. Graders also reject the plausible but wrong fix
(`kubectl apply` of the app by hand instead of fixing the sync, suspending
the failing object, pointing Flux at a second repository, creating objects
in the cluster that are not in Git). A lab's `question.md` and `solution.md`
must match what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Each environment
runs Gitea plus four or six Flux controllers.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Concepts:** [core concepts](https://fluxcd.io/flux/concepts/),
  [components](https://fluxcd.io/flux/components/),
  [OpenGitOps principles](https://opengitops.dev/)
- **Installation:** [installation](https://fluxcd.io/flux/installation/),
  [bootstrap a generic Git server](https://fluxcd.io/flux/installation/bootstrap/generic-git-server/),
  [bootstrap Gitea](https://fluxcd.io/flux/installation/bootstrap/gitea/),
  [bootstrap GitHub](https://fluxcd.io/flux/installation/bootstrap/github/)
- **APIs:** [GitRepository](https://fluxcd.io/flux/components/source/gitrepositories/),
  [Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/)
- **CLI:** [flux command reference](https://fluxcd.io/flux/cmd/)
- **The landscape:** Flux's page on the CNCF site,
  <https://www.cncf.io/projects/flux/> (graduated project).

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
