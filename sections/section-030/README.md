# Section 030: Bootstrapping Flux

Installing Flux is easy: `flux install` puts the controllers in a cluster in a minute. But a cluster installed that way is not run from Git. Nothing records which version of Flux runs, how it is configured, or which repository it should follow. If the cluster is lost, nobody knows how to build it again.

This section is about the command that closes that gap. `flux bootstrap` installs the controllers, commits their manifests to a Git repository, and makes Flux reconcile itself from that repository. After bootstrap, an upgrade of Flux and a new application are both just a commit. The section also covers the credential Flux uses to read that repository, because a rotated password or key is the most common reason a bootstrapped cluster stops following Git.

**Topic covered:** Bootstrap

## What you will learn

- The steps `flux bootstrap` takes, in order, and the three files it writes under `<path>/flux-system`.
- Why a bootstrapped Flux manages itself, and why running bootstrap again is safe.
- The difference between `flux install` and `flux bootstrap`, and the bootstrap commands for GitHub, GitLab, Gitea, Bitbucket Server and any other Git server.
- Running `flux bootstrap git` against a Git server over HTTP with a user and password.
- Verifying an installation: `flux check`, the Flux custom resource definitions (CRDs), and `flux get all`.
- Deploying an application by committing a Flux `Kustomization` object next to `flux-system`.
- What the `flux-system` Secret holds for token authentication and for SSH, read-only and read-write deploy keys, and how to rotate a credential.

## The learning path

### 1. Bootstrap Flux From A Git Repository

The module starts at its landing page, which also launches the playground. The playground runs a Git server, Gitea, with the repository `gitops/fleet`, and puts the Flux command-line tool on your machine. Flux itself is not installed yet.

1. What flux bootstrap Does
2. Bootstrapping A Kind Cluster And Verifying It, followed by the lab **Bootstrap Flux Into A Kind Cluster**
3. Deploy Keys, Tokens And The flux-system Secret
4. Summary

## Section capstone: Recover A Cluster Whose Bootstrap Broke

The capstone is one graded scenario that combines the whole module. A bootstrapped cluster stopped following Git on the day the Git password was rotated. Someone also patched a `flux-system` object by hand, and a colleague pushed a bad change. Three faults hide behind each other, and Flux cannot repair itself until you find the first one. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-094-capstone-030
```
