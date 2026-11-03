# Build And Overlays

Before the controller applies anything, it builds the folder named in `spec.path`. The build is done by the same code as the `kustomize build` command. This part shows what the build does, and how to preview it before Flux applies it.

The commands below need the `GitRepository` `fleet` in the namespace `flux-system`, which points at `gitops/fleet` and follows the branch `main`:

<!-- astrona:playground:renew -->

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
flux create source git fleet \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --branch=main --secret-ref=fleet-auth --interval=1m
```

## What the controller builds

The controller looks at the folder in `spec.path` inside the artifact. If the folder has a `kustomization.yaml`, the controller builds exactly what that file describes. If it does not, the controller generates a `kustomization.yaml` that lists every YAML file in the folder and its subfolders. The first case gives you control over the list of files and over everything Kustomize can do. The second case is simple, but it applies everything it finds.

The result of the build is one stream of manifests. That stream is what the later steps work on: variables are replaced in it, and it is applied to the cluster.

## Base and overlay

A **base** holds the manifests that every environment shares. An **overlay** points at a base and changes some fields. The folder `apps/layered` in the repository has this shape:

```text
apps/layered/base/                 namespace, deployment, kustomization.yaml
apps/layered/overlays/staging/     kustomization.yaml with a patch
```

The base runs 1 replica and sets the message `base`. The overlay refers to the base with `resources: [../../base]` and adds a patch that sets 2 replicas and the message `staging overlay`. Create a Flux `Kustomization` that builds the overlay:

```sh
flux create kustomization layered \
  --source=GitRepository/fleet \
  --path=./apps/layered/overlays/staging \
  --prune=true --wait=true --interval=5m
flux get kustomizations
kubectl -n layered get deployment layered \
  -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].env[0].value}{"\n"}'
```

The Deployment has 2 replicas and the message `staging overlay`. The base and the overlay are separate folders, and the Flux `Kustomization` chose which one to apply. A second environment is a second overlay folder and a second Flux `Kustomization`; the base is shared.

## Preview the build

A mistake in a build is cheaper to find before you push. `flux build kustomization` runs the same build on your machine and prints the manifests. It needs the Flux `Kustomization` to exist in the cluster, and a local folder to build:

```sh
git clone http://gitea.localtest.me:3000/gitops/fleet.git fleet-clone
flux build kustomization layered --path ./fleet-clone/apps/layered/overlays/staging
```

The output is the Namespace and the Deployment with the overlay applied. Change a value in the overlay file and run the command again to see the effect, without a commit. To compare with what runs in the cluster, use `flux diff kustomization`:

```sh
flux diff kustomization layered --path ./fleet-clone/apps/layered/overlays/staging
```

With no difference the command exits with code 0. With a difference it prints the changes and exits with code 1, which makes it usable in a pipeline that checks a pull request.

## Where a build fails

A build error comes first, before any object is touched. A missing file in the `resources` list, a patch that does not match any object, or invalid YAML stops the run, and nothing is applied. The `Ready` condition of the Flux `Kustomization` shows the message and the object keeps the last applied state:

```sh
kubectl -n flux-system get kustomization layered \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```

On a healthy object this prints the revision that was applied. After a failed build it prints the error from Kustomize instead. When the message talks about files, patches or resources, the problem is in the build step, and the fix is in Git.

## Try it

1. Create the Flux `Kustomization` `layered` as shown, and read the replicas and the message from the Deployment.
2. Run `flux build kustomization` on the overlay and on the base folder, and compare the replicas.
3. Change `replicas` to 3 in your clone without committing, and run `flux diff kustomization`. What does the output say, and what is the exit code?
