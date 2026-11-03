# Summary

kustomize-controller builds the folder named in a Flux `Kustomization`, replaces variables, applies the result, removes what disappeared from Git, and waits for health. This module showed each step and how to limit what the controller may do.

## What you learned

The build uses the `kustomization.yaml` in the folder, or generates one that lists every manifest when there is none. A base holds what every environment shares, and an overlay refers to the base and changes fields. `flux build kustomization` prints the result on your machine, and `flux diff kustomization` compares it with the cluster and exits with code 1 when there is a difference.

The Flux `Kustomization` can change the built result with `patches`, `images`, `namePrefix`, `nameSuffix`, `commonMetadata` and `targetNamespace`. `targetNamespace` overrides the namespace of every namespaced object, and the controller does not create a namespace that does not exist.

`postBuild.substitute` and `postBuild.substituteFrom` replace `${name}` and `${name:=default}` after the build. A missing variable without a default becomes an empty string, a missing ConfigMap or Secret stops the run unless `optional: true` is set, and `$${name}` writes a literal `${name}`. The `kind` of a `substituteFrom` entry must match the real object.

`spec.serviceAccountName` makes the controller impersonate a service account in the namespace of the Flux `Kustomization`, so an apply is limited to the rights of that account. `--default-service-account` and `--no-cross-namespace-refs` make the rule mandatory for tenants. The `Ready` message tells whether an error is in the build, the substitution, the apply or the wait.

The key facts to remember are these:

- The controller builds first, substitutes second and applies last.
- Preview with `flux build kustomization` and `flux diff kustomization` before you push.
- Put shared values in a ConfigMap or Secret, and give every variable a default.
- Use a service account per tenant, and enforce it with the controller flags.
- Read the message of the `Ready` condition first, and map it to a step.

<!-- astrona:playground:destroy -->
