# Variable Substitution

Two clusters often run the same manifests with a few different values: a domain name, a replica count, a message. Copying the files per cluster means fixing every copy when something changes. With **post-build substitution**, the manifests contain variables, and the Flux `Kustomization` of each cluster supplies the values.

The commands below need the `GitRepository` `fleet` in the namespace `flux-system`. The folder `apps/templated` holds a Deployment that uses two variables:

<!-- astrona:playground:renew -->

```yaml
spec:
  replicas: ${replicas:=1}
  ...
        env:
          - name: PODINFO_UI_MESSAGE
            value: "${ui_message:=no message set}"
```

## Where the values come from

The field `spec.postBuild` has two sources. `substitute` is a map written directly in the Flux `Kustomization`. `substituteFrom` is a list of ConfigMaps and Secrets in the namespace of the Flux `Kustomization`. Each entry has a `kind` (`ConfigMap` or `Secret`) and a `name`. Every key in the object becomes a variable. When a name is in both places, the value from `substitute` wins.

Create the values as a ConfigMap, and the Flux `Kustomization` that reads it:

```sh
kubectl -n flux-system create configmap cluster-vars \
  --from-literal=ui_message="hello from cluster-vars"
flux create kustomization templated \
  --source=GitRepository/fleet --path=./apps/templated \
  --prune=true --wait=true --interval=5m \
  --export > templated.yaml
```

The `flux create kustomization` command has no flag for `postBuild`, so add it to the exported file and apply it:

```yaml
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-vars
```

```sh
kubectl apply -f templated.yaml
flux get kustomizations
kubectl -n templated get deployment templated \
  -o jsonpath='{.spec.template.spec.containers[0].env[0].value}{"\n"}'
```

The message from the ConfigMap is in the environment of the running Deployment. Secrets work the same way, and are the place for values that must not be in Git. The values in a Secret are still readable by anyone who can read the Secret, so limit that access.

## Defaults and missing values

The syntax is `${name}` or `${name:=default}`. With `:=`, the default is used when the variable has no value. A variable without a default and without a value is replaced by an empty string, which can silently produce a broken manifest. That is why the examples above carry a default. Note that `replicas` in the example has no value in the ConfigMap, so the Deployment runs 1 replica. Add `replicas` to the ConfigMap and reconcile, and the value changes:

```sh
kubectl -n flux-system patch configmap cluster-vars --type=merge -p '{"data":{"replicas":"2"}}'
flux reconcile kustomization templated
kubectl -n templated get deployment templated -o jsonpath='{.spec.replicas}{"\n"}'
```

A change to the ConfigMap is picked up at the next reconcile, which is the next interval or a manual `flux reconcile`.

If the ConfigMap or Secret in `substituteFrom` does not exist, the run stops with an error, and nothing is applied. Set `optional: true` on the entry to continue without it. The `kind` must match the object: a `ConfigMap` entry never finds a Secret.

## Limits and escaping

Variable names use letters, digits and underscores, and cannot start with a digit. Values from a ConfigMap or Secret are strings. A Deployment field that needs a number accepts the replaced text, because the replacement happens in the YAML text before it is parsed.

Some files contain `${...}` for another tool, for example a shell script in a ConfigMap. Write `$${name}` to produce a literal `${name}`. To switch the replacement off for one object, add the annotation `kustomize.toolkit.fluxcd.io/substitute: disabled` to that object in Git.

## Why this runs after the build

The controller builds the folder first and substitutes second, so the substitution sees the final YAML, including the result of patches. A variable in a file that the build does not include is never seen. When the message is about a missing variable source, the problem is in the Flux `Kustomization`. When the value is empty or wrong, look at the keys in the ConfigMap or Secret.

## Try it

1. Create the ConfigMap `cluster-vars` and the Flux `Kustomization` `templated`, and read the message from the Deployment.
2. Delete the key `ui_message` from the ConfigMap, reconcile, and read the message again. Which value do you see?
3. Change the `kind` in `substituteFrom` to `Secret` and read the `Ready` message. Set it back.

## Your mission: Fix The Variable Substitution

You now know how the controller reads values and where it applies them. The graded lab gives you a Flux `Kustomization` that reads its variables from the wrong kind of object and puts its workloads in a namespace that does not exist. Fix both, so that the message from the ConfigMap reaches the running Deployment.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-094-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS094.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-094-lab-020-03
astrona start ats-094-playground-020-03
```
