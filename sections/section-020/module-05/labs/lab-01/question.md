# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** The notification controller

## Scenario

The platform team wants a message for every event of the Flux `Kustomization` `podinfo` and of the `GitRepository` `fleet`, both in the namespace `flux-system`. Informational events, such as a successful apply, must be sent too, not only errors.

A colleague created a `Provider` named `team-webhook` and an `Alert` named `app-events`, both in `flux-system`. Both objects apply without an error, but the `Alert` is not working as intended. The address of the `Provider` is a lab placeholder; nothing listens there, and you do not need to receive any message.

## Your task

1. Find out why the `Alert` `app-events` is not ready, and why it would not match the events described above. There is more than one cause.
2. Fix the `Alert` so that it uses the `Provider` `team-webhook`, selects the two objects in the namespace `flux-system`, and sends events of every severity.
3. Confirm that the `Alert` and the `Provider` are ready.

## Constraints

- Keep the names `app-events` and `team-webhook`, the type `generic` and the address of the `Provider`.
- Do not create new Providers or Alerts, and do not suspend any object.
- Do not change the Flux `Kustomization` or the `GitRepository`.

## Done when

- The `Alert` `app-events` is `Ready` and refers to the `Provider` `team-webhook`.
- Its event sources are the `Kustomization` `podinfo` and the `GitRepository` `fleet`, both in the namespace `flux-system`.
- Its event severity is `info`.
