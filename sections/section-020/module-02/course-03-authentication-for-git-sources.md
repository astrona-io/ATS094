# Authentication For Git Sources

A private repository answers only to clients that prove who they are. source-controller is the only Flux controller that talks to Git, so it is the only one that needs credentials. They live in a Kubernetes Secret in the same namespace as the source, and the field `spec.secretRef` names it. This part covers the three methods you will meet: HTTP basic authentication, SSH keys, and TLS certificates.

The commands below need the `GitRepository` `fleet` in the namespace `flux-system`:

<!-- astrona:playground:renew -->

## HTTP with a user name and a password or token

The simplest method is a user name and a password. For GitHub or GitLab, the password is a personal access token. The Secret has two keys, `username` and `password`. Create it with the `flux` tool, which builds the Secret with the right keys:

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
kubectl -n flux-system get secret fleet-auth -o jsonpath='{.data}' | jq 'keys'
```

The list of keys is `password` and `username`. The `--url` flag decides the type of the Secret: an `http` or `https` URL gives a basic authentication Secret. Use a token with read-only access to one repository, and rotate it on a schedule. A source with a read-only token cannot change the repository, even if someone steals the Secret.

## SSH with a key pair

With an SSH URL, the Secret holds a private key and the list of trusted host keys. When you do not pass a key, `flux` generates a key pair and prints the public key:

```sh
flux create secret git fleet-ssh \
  --url=ssh://git@github.com/example/fleet \
  --export
```

The `--export` flag prints the Secret instead of creating it. The Secret has the keys `identity` (the private key), `identity.pub` (the public key) and `known_hosts` (the trusted server key). The command fetches the host key from the server when it creates a Secret. Add the public key as a read-only **deploy key** to the repository on the Git host. A deploy key belongs to one repository, unlike the key of a person.

The `known_hosts` entry matters. Without it, source-controller cannot tell whether the server is the real one, and it refuses to connect. When a server changes its host key, update the Secret.

## TLS and a private certificate authority

A Git server with a certificate from a private certificate authority (CA) fails the check unless source-controller knows that CA. The Secret then holds the CA certificate under the key `ca.crt`. Optionally it holds a client certificate and key as `tls.crt` and `tls.key`, for servers that require client certificates:

```sh
flux create secret tls fleet-tls --ca-crt-file=ca.crt --export
```

Use `--export` first to read the YAML. Put the name of the Secret in `spec.secretRef`. Name Secrets by purpose, so that a rotation changes one thing.

## Wrong credentials: what you see

Read the failure once so you recognise it later. Point the source at a Secret that does not exist:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"secretRef":{"name":"fleet-missing"}}}'
flux get sources git
kubectl -n flux-system get gitrepository fleet \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

The source is no longer ready, and the message says the Secret `fleet-missing` was not found. A wrong password gives a different message: the Git server answers with an authentication error. Read the message to learn which of the two it is: a Secret problem (name, namespace, keys) or a server problem (user, token, key, host key). Put the correct name back:

```sh
kubectl -n flux-system patch gitrepository fleet --type=merge \
  -p '{"spec":{"secretRef":{"name":"fleet-auth"}}}'
flux reconcile source git fleet
```

## Where the credentials belong

The Secret must be in the namespace of the source. A `GitRepository` cannot use a Secret from another namespace. Do not commit the Secret to Git in plain text. Create it from the command line once, or store it encrypted with a tool such as SOPS and let Flux decrypt it. Bootstrap does this for the credentials of the `flux-system` source.

You now know how to give source-controller access and how to read why access fails. The graded lab combines this with a reference: a source with a wrong Secret name that also follows the wrong reference.

## Common pitfalls

> [!WARNING]
> - **A Secret in the wrong namespace.** The Secret must be in the namespace of the source.
> - **A key with write access.** Give the source a read-only token or deploy key. It never needs to push, unless image automation uses it.
> - **Forgetting `known_hosts`.** Without it, SSH sources refuse to connect.
> - **Treating a token as permanent.** Tokens expire. A source that worked for months can fail on the day the token ends.

## Your mission: Pin The GitRepository To The Reviewed Release

You can now choose a reference and read why a source cannot authenticate. The graded lab gives you a `GitRepository` with a wrong Secret name that also follows the branch `main`, where one commit was never reviewed. Fix the access, and pin the source to the reviewed tag `release-1`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-020-02
astrona start ats-094-playground-020-02
```
