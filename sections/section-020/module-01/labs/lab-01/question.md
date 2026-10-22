# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** The GitOps Toolkit

## Scenario

The platform team wants Flux to watch the `podinfo` image in its container registry, so a later change can update the image tag automatically. A teammate wrote the object below and tried to apply it. `kubectl` refused it.

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

## Your task

1. Save the YAML above as `imagerepository-podinfo.yaml` and apply it. Read why the API server refuses it.
2. Add the controllers Flux needs for image scanning and for writing image updates back to Git: `image-reflector-controller` and `image-automation-controller`.
3. Apply `imagerepository-podinfo.yaml` again and make sure the `ImageRepository` becomes ready.

## Constraints

- **Keep the four default controllers** (`source-controller`, `kustomize-controller`, `helm-controller`, `notification-controller`) installed and Available. An installation that lists only the image controllers is graded as wrong.
- Install the controllers with the `flux` command-line tool. Do not apply controller manifests you wrote or downloaded yourself.
- Do not change the `ImageRepository` YAML.
- The scan needs outbound internet to `ghcr.io`. If your network blocks it, the last check cannot pass.

## Done when

- `image-reflector-controller` and `image-automation-controller` are Available in `flux-system`, and the CRDs `imagerepositories`, `imagepolicies` and `imageupdateautomations` in the group `image.toolkit.fluxcd.io` exist.
- The four default controllers are still Available, and `flux check` passes.
- The `ImageRepository` `podinfo` in `flux-system` is `Ready`.
