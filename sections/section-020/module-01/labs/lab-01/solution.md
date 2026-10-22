# Solution: Add The Image Automation Controllers

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: both image controllers are Available and their CRDs exist, the four default controllers are still Available and `flux check` passes, and the `ImageRepository` `podinfo` is `Ready`.

## Step 1: Reproduce the refusal

Save the YAML from the task as `imagerepository-podinfo.yaml`:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 5m
```

Apply it:

```sh
kubectl apply -f imagerepository-podinfo.yaml
```

The API server refuses the object. `kubectl` says it found no match for the kind `ImageRepository` in the version `image.toolkit.fluxcd.io/v1`, and suggests that the CustomResourceDefinitions (CRDs) may need to be installed first. The YAML is fine. The kind simply does not exist in this cluster yet.

## Step 2: Confirm which controller is missing

Check whether the API group exists, and which Flux controllers run:

```sh
kubectl api-resources --api-group=image.toolkit.fluxcd.io
kubectl -n flux-system get deployments
```

The first command lists no kinds, so no CRD of the image group is installed. The second lists only the four default controllers. `ImageRepository` belongs to image-reflector-controller, and the task also asks for image-automation-controller, which owns `ImageUpdateAutomation`. Neither is installed by default.

## Step 3: Add the two image controllers

Use `--components-extra`, which adds components to the default list. Running `flux install` again on a cluster that already runs Flux is safe: it applies the manifests for every component you name and leaves your Flux objects alone.

```sh
flux install --components-extra=image-reflector-controller,image-automation-controller
```

The command applies the image CRDs and the two new Deployments and waits until every controller is ready.

Do not use `--components=image-reflector-controller,image-automation-controller`. That flag replaces the default list, so the four default controllers are not part of the installation you asked for, and the grader checks that they are still there.

## Step 4: Apply the ImageRepository again

The kind exists now, so the API server stores the object:

```sh
kubectl apply -f imagerepository-podinfo.yaml
```

Then check the result:

```sh
flux get images repository podinfo
```

After the first scan, the `Ready` column shows `True` and the message says the scan was successful and how many tags it found. If it still shows no status, wait a few seconds and run the command again; the scan has to reach `ghcr.io`.

## Step 5: Check the whole installation

```sh
flux check
kubectl -n flux-system get deployments
```

`flux check` ends by saying that all checks passed, and the Deployment list has six controllers, each with one ready replica.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `flux install --components=image-reflector-controller,image-automation-controller` | Replaces the default list; the grader requires the four default controllers |
| Apply only the CRDs | The `ImageRepository` is stored, but no controller scans it, so it never becomes `Ready` |
| Change `apiVersion` in the YAML until `kubectl` accepts it | No version of the image kinds exists until the controllers are installed |
| Add only `image-reflector-controller` | The `ImageRepository` works, but the task also asks for `image-automation-controller` |

## Common mistakes

- Reading "no matches for kind" as a typing mistake instead of a missing CRD.
- Forgetting that the scan needs outbound internet to `ghcr.io`.
- Running `flux install` with a different Flux CLI version, which installs controllers of that other version.

## Practice on your own

- Run `kubectl api-resources --api-group=image.toolkit.fluxcd.io` again and name the controller that owns each kind.
- Delete the `image-reflector-controller` Deployment, apply a second `ImageRepository`, and watch it stay without conditions. Run the same `flux install` command again to bring the controller back.
- Run `flux install --components-extra=image-reflector-controller,image-automation-controller --export` and look for the image Deployments in the YAML without changing the cluster.
